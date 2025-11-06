import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Recipe Info =====
            if (recipe.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Image failed to load');
                    },
                  ),
                ),
              ),
            if (recipe.source.isNotEmpty)
              Text(
                'Source: ${recipe.source}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            if (recipe.chef.isNotEmpty)
              Text(
                'Chef: ${recipe.chef}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                recipe.description,
                style: const TextStyle(fontSize: 16),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(thickness: 1),

            // ===== Ingredients =====
            const Text('Ingredients:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            ...recipe.ingredients.map((ing) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '• '
                    '${ing.quantity.isNotEmpty ? '${ing.quantity} - ' : ''}'
                    '${ing.item}'
                    '${ing.note.isNotEmpty ? ' (${ing.note})' : ''}',
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                )),

            const SizedBox(height: 16),
            const Divider(thickness: 1),

            // ===== Steps =====
            const Text('Steps:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            ...recipe.steps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '${entry.key + 1}. ${entry.value.instruction}',
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ),

            const SizedBox(height: 16),

            // ===== Sub-Recipes =====
            if (recipe.subRecipes.isNotEmpty) ...[
              const Divider(thickness: 1),
              const Text('Sub-Recipes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ...recipe.subRecipes.map((sub) => _buildSubRecipe(sub)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubRecipe(Recipe sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub.name,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (sub.yieldInfo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 6.0),
              child: Text('Yield: ${sub.yieldInfo}',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),

          // Sub-Recipe Ingredients
          const Text('Ingredients:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          ...sub.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Text(
                  '• '
                  '${ing.quantity.isNotEmpty ? '${ing.quantity} - ' : ''}'
                  '${ing.item}'
                  '${ing.note.isNotEmpty ? ' (${ing.note})' : ''}',
                  style: const TextStyle(fontSize: 15),
                ),
              )),
          const SizedBox(height: 8),

          // Sub-Recipe Steps
          const Text('Steps:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          ...sub.steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '${entry.key + 1}. ${entry.value.instruction}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
