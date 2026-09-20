import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import 'results_list_screen.dart';
import 'saved_recipes_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/recipe_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _categories = [
    'Cocktail', 'Bread', 'Brunch', 'Starter', 'Main', 'Sides', 'Dessert',
  ];

  final TextEditingController _searchController = TextEditingController();
  Map<String, Recipe?> _randomMenu = {};
  List<Recipe> _topRecipes = [];

  @override
  void initState() {
    super.initState();
    _loadRandomMenu();
    _loadTopRecipes();
  }

  Future<void> _loadRandomMenu() async {
  final allRecipes = await RecipeService.getAllRecipes(); // assumes all recipes from JSON

  final Set<String> usedIds = {}; // track duplicates
  final Map<String, Recipe?> randomMenu = {};

  for (final category in _categories) {
    // find all recipes matching this category and not already used
    final candidates = allRecipes.where((r) {
      return r.category.contains(category) && !usedIds.contains(r.name);
    }).toList();

    if (candidates.isNotEmpty) {
      candidates.shuffle();
      final selected = candidates.first;
      randomMenu[category] = selected;
      usedIds.add(selected.name); // prevent repeats
    } else {
      randomMenu[category] = null;
    }
  }

  setState(() => _randomMenu = randomMenu);
}

  Future<void> _loadTopRecipes() async {
    final top = await RecipeService.getTop10Recipes();
    setState(() => _topRecipes = top);
  }

  void _searchRecipes() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final results = await RecipeService.searchRecipes(query);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsListScreen(query: query, recipes: results),
      ),
    );
  }

  Widget _buildRandomMenuCarousel() {
    if (_randomMenu.isEmpty) return const SizedBox();
    return SizedBox(
      height: 300,
      child: PageView(
        controller: PageController(viewportFraction: 0.8),
        children: _randomMenu.entries
            .where((e) => e.value != null)
            .map((entry) => RecipeCard(recipe: entry.value!))
            .toList(),
      ),
    );
  }

  Widget _buildTop10Recipes() {
    return SizedBox(
      height: 350,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _topRecipes.length,
        itemBuilder: (context, index) => SizedBox(
          width: 160,
          child: RecipeCard(recipe: _topRecipes[index], height: 100),
        ),
      ),
    );
  }

  Widget _buildCategoriesBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (_, index) {
          final category = _categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ActionChip(
              label: Text(category),
              onPressed: () {
                _searchController.text = category;
                _searchRecipes();
              },
              backgroundColor: const Color.fromARGB(123, 176, 174, 175),
            ),
          );
        },
      ),
    );
  }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
    body: CustomScrollView(
      slivers: [
        AppHeader(
          onOpenSavedRecipes: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedRecipesScreen()),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search recipes, chefs, restaurants, ingredients...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 15, 14, 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _searchRecipes(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _searchRecipes,
                      child: const Text('Elevate'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildCategoriesBar(),
                const SizedBox(height: 16),

                if (_randomMenu.isNotEmpty) ...[
                  const Text(
                    "Not sure what to cook? Try this curated menu to wow your guests!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  const SizedBox(height: 8),
                  _buildRandomMenuCarousel(),
                  const SizedBox(height: 24),
                ],

                if (_topRecipes.isNotEmpty) ...[
                  const Text(
                    'Top 10 Recipes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  const SizedBox(height: 8),
                  _buildTop10Recipes(),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

}
