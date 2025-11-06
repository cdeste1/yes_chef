import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen.dart';

class RandomMealScreen extends StatelessWidget {
  final Map<String, Recipe?> mealSet;

  const RandomMealScreen({super.key, required this.mealSet});

  Widget _buildMealCard(String title, Recipe? recipe) {
    if (recipe == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to recipe detail screen
          Navigator.push(
            _navigatorKey.currentContext!,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  recipe.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(
                        height: 180,
                        child: Center(child: Icon(Icons.broken_image, size: 50)),
                      ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$title: ${recipe.name}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (recipe.source.isNotEmpty)
                    Text('Source: ${recipe.source}',
                        style: const TextStyle(
                            fontStyle: FontStyle.italic, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    recipe.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigator key hack to allow push inside StatelessWidget
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Your Curated Meal'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                _buildMealCard('Cocktail', mealSet['cocktail']),
                _buildMealCard('Starter', mealSet['starter']),
                _buildMealCard('Main', mealSet['main']),
                _buildMealCard('Dessert', mealSet['dessert']),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
