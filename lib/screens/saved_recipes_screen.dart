import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/favorites_service.dart';
import '../services/recipe_service.dart';
import '../widgets/recipe_card.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  List<Recipe> _allRecipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final recipes = await RecipeService.getAllRecipes();
    if (!mounted) return;
    setState(() {
      _allRecipes = recipes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Recipes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Set<String>>(
              valueListenable: FavoritesService.favoritesNotifier,
              builder: (context, favoriteSlugs, _) {
                final favorites = FavoritesService.filterFavorites(_allRecipes);
                if (favorites.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No saved recipes yet — tap the heart on any recipe to save it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) =>
                      RecipeCard(recipe: favorites[index]),
                );
              },
            ),
    );
  }
}
