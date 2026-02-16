import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recipe_model.dart';
import '../widgets/ad_banner.dart';

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
                  child: Image.asset(
                    recipe.imageUrl,
                    fit: BoxFit.fitHeight,
                    width: double.infinity,
                    height: 300,
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
                'Inspiring Chef: ${recipe.chef}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                recipe.description,
                style: const TextStyle(fontSize: 16),
              ),
              
            ],
            if (recipe.yieldInfo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                recipe.yieldInfo,
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

            if (recipe.specialtools.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const Text(
                'Speciality Items:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),

              ...recipe.specialtools.map((tool) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 15)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color),
                              children: [
                                TextSpan(text: tool.item),
                                if (tool.link.isNotEmpty) ...[
                                  const TextSpan(text: '  '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () async {
                                        final uri = Uri.parse(tool.link);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                      child: const Text(
                                        'Need it? Click here to start cooking',
                                        style: TextStyle(
                                          color: Color(0xFFF58220),
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'As an Amazon Associate, Yes Chef! may earn from qualifying purchases.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            // ===== Sommelier’s Recommendation =====
            if (recipe.winePairings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2B2B2B),
                      const Color(0xFF1A1A1A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.wine_bar, color: Color(0xFFF58220)),
                        SizedBox(width: 8),
                        Text(
                          "Sommelier’s Recommendation",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ...recipe.winePairings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "• ${w.name}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (w.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14, top: 4),
                                child: Text(
                                  w.notes,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],



            // ===== Steps =====
            const Text('Steps:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            ...recipe.steps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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

            const SizedBox(height: 24),

            // ===== ⬇️ Added collapsible disclaimer =====
            const RecipeDisclaimer(),
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
              const AdBanner(),
        ],
      ),
    );
  }
}

//
// === Collapsible Disclaimer Widget ===
//
class RecipeDisclaimer extends StatelessWidget {
  const RecipeDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: Colors.grey[600],
        collapsedIconColor: Colors.grey[600],
        title: Text(
          "More Info",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              "Disclaimer:\n"
              "The information and recipes provided within this application are intended for "
              "general informational and personal use only. Yes Chef makes no guarantees "
              "regarding accuracy, ingredient safety, or cooking outcomes. Users are responsible "
              "for checking allergen information, food safety temperatures, and proper handling "
              "of all ingredients. By using this app, you acknowledge that Yes Chef and its "
              "contributors are not liable for any adverse reactions, injuries, or results "
              "that may occur.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}