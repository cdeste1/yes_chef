import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import 'recipe_detail_screen.dart';
import '../Widgets/ad_banner.dart'; // ✅ add this import for ad banner

class ResultsListScreen extends StatelessWidget {
  final List<Recipe> recipes;
  final String query;

  const ResultsListScreen({
    super.key,
    required this.recipes,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "$query"'),
      ),
      body: Column(
        children: [
          // Main recipe list
          Expanded(
            child: recipes.isEmpty
                ? const Center(
                    child: Text('No recipes found.'),
                  )
                : ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        child: ListTile(
                          title: Text(
                            recipe.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${recipe.source}\n${recipe.description}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),

          // ✅ Ad banner stays pinned to bottom
          const AdBanner(),
        ],
      ),
    );
  }
}