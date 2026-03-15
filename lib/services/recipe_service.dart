/*import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';

class RecipeService {
  /// Load all recipes from the bundled JSON file
  static Future<List<Recipe>> loadRecipes() async {
    final String response = await rootBundle.loadString('assets/recipes.json');
    final List<dynamic> data = json.decode(response);

    return data.map((item) {
      final recipeJson = item['recipe'] ?? item;
      return Recipe.fromJson(recipeJson);
    }).toList();
  }

  /// Simple wrapper so other widgets can easily get all recipes
  static Future<List<Recipe>> getAllRecipes() async {
    return await loadRecipes();
  }

  /// Calculate simple fuzzy match score (0–1)
  static double _similarity(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();

    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    int distance = _levenshtein(a, b);
    int maxLen = max(a.length, b.length);
    return 1.0 - (distance / maxLen);
  }

  /// Levenshtein distance (edit distance)
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<List<int>> matrix =
        List.generate(s.length + 1, (_) => List.filled(t.length + 1, 0));

    for (int i = 0; i <= s.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= t.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    return matrix[s.length][t.length];
  }

  /// Enhanced multi-field search with fuzzy and ingredient matching
  static Future<List<Recipe>> searchRecipes(String query) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final allRecipes = await loadRecipes();

    // FIRST: strict category mode
  final categories = ['cocktail', 'starter', 'main', 'sides', 'dessert', 'bread'];
  if (categories.contains(lowerQuery)) {
    return allRecipes
        .where((r) => r.category.toLowerCase() == lowerQuery)
        .toList();
  }

  // Otherwise: normal fuzzy search

    return allRecipes.where((recipe) {
      bool matchFound = false;

      // --- Title, source, chef, description ---
      if (recipe.name.toLowerCase().contains(lowerQuery) ||
          recipe.source.toLowerCase().contains(lowerQuery) ||
          recipe.category.toLowerCase().contains(lowerQuery) ||
          recipe.keywords.toLowerCase().contains(lowerQuery) ||
          recipe.chef.toLowerCase().contains(lowerQuery) ||
          recipe.description.toLowerCase().contains(lowerQuery)) {
        matchFound = true;
      }

      // --- Ingredients ---
      if (!matchFound) {
        for (var ing in recipe.ingredients) {
          if (ing.item.toLowerCase().contains(lowerQuery) ||
              ing.note.toLowerCase().contains(lowerQuery) ||
              ing.quantity.toLowerCase().contains(lowerQuery)) {
            matchFound = true;
            break;
          }
        }
      }

      // --- Special Tools ---
      if (!matchFound) {
        for (var tool in recipe.specialtools) {
          if (tool.item.toLowerCase().contains(lowerQuery) ||
              tool.link.toLowerCase().contains(lowerQuery)) {
            matchFound = true;
            break;
          }
        }
      }


      // --- Steps ---
      if (!matchFound) {
        for (var step in recipe.steps) {
          if (step.instruction.toLowerCase().contains(lowerQuery)) {
            matchFound = true;
            break;
          }
        }
      }

      // --- Sub-recipes ---
      if (!matchFound) {
        for (var sub in recipe.subRecipes) {
          if (sub.name.toLowerCase().contains(lowerQuery)) {
            matchFound = true;
            break;
          }
          for (var ing in sub.ingredients) {
            if (ing.item.toLowerCase().contains(lowerQuery)) {
              matchFound = true;
              break;
            }
          }
        }
      }

      // --- Fuzzy title/chef match ---
      if (!matchFound) {
        double simName = _similarity(recipe.name, query);
        double simChef = _similarity(recipe.chef, query);
        if (simName > 0.6 || simChef > 0.6) {
          matchFound = true;
        }
      }

      return matchFound;
    }).toList();
  }
  /// Returns Top 10 recipes
  static Future<List<Recipe>> getTop10Recipes() async {
    final allRecipes = await loadRecipes();
    if (allRecipes.length <= 10) return allRecipes;
    return allRecipes.sublist(0, 10);
  }
  /// Returns a single random recipe
  static Future<Recipe?> randomRecipe() async {
    final allRecipes = await loadRecipes();
    if (allRecipes.isEmpty) return null;
    final random = Random();
    return allRecipes[random.nextInt(allRecipes.length)];
  }

  /// Returns a curated random meal: cocktail, starter, main, dessert
static Future<Map<String, Recipe?>> randomMealSet() async {
  final allRecipes = await loadRecipes();
  if (allRecipes.isEmpty) {
    return {
      'cocktail': null,
      'bread': null,
      'starter': null,
      'main': null,
      'sides': null,
      'dessert': null,
    };
  }

  final random = Random();

  // Group recipes by category
  final cocktails = allRecipes.where((r) => r.category.toLowerCase() == 'cocktail').toList();
  final breads = allRecipes.where((r) => r.category.toLowerCase() == 'bread').toList();
  final starters  = allRecipes.where((r) => r.category.toLowerCase() == 'starter').toList();
  final mains     = allRecipes.where((r) => r.category.toLowerCase() == 'main').toList();
  final sides = allRecipes.where((r) => r.category.toLowerCase() == 'sides').toList();
  final desserts  = allRecipes.where((r) => r.category.toLowerCase() == 'dessert').toList();

  // Helper: get random recipe from a list
  Recipe? pickRandom(List<Recipe> list) =>
      list.isNotEmpty ? list[random.nextInt(list.length)] : null;

  // Try to pick directly from categories first
  Recipe? cocktail = pickRandom(cocktails);
  Recipe? bread = pickRandom(breads);
  Recipe? starter  = pickRandom(starters);
  Recipe? main     = pickRandom(mains);
  Recipe? sides1 = pickRandom(sides);
  Recipe? dessert  = pickRandom(desserts);

  // If any category missing, fallback to random
  if (cocktail == null || starter == null || main == null || dessert == null) {
    final fallback = List.from(allRecipes);
    cocktail ??= fallback[random.nextInt(fallback.length)];
    bread ??= fallback[random.nextInt(fallback.length)];
    starter  ??= fallback[random.nextInt(fallback.length)];
    main     ??= fallback[random.nextInt(fallback.length)];
    sides1    ??= fallback[random.nextInt(fallback.length)];
    dessert  ??= fallback[random.nextInt(fallback.length)];
  }

  return {
    'cocktail': cocktail,
    'bread': bread,
    'starter': starter,
    'main': main,
    'sides': sides1,
    'dessert': dessert,
  };
}
 
}*/

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';

class RecipeService {
  static const String _url = 'https://pub-3ae50d56fa834654954be23601470560.r2.dev/assets/recipes.json'; // 👈 your R2 URL
  static const String _cacheKey = 'cached_recipes';
  static const int _cacheTtlHours = 24;

  // ─── Core Loader ────────────────────────────────────────────────────────────

  static Future<List<Recipe>> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
  
    // Try network first
    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await prefs.setString(_cacheKey, response.body);
        await prefs.setString('${_cacheKey}_time', DateTime.now().toIso8601String());
        return _parseRecipes(response.body);
      }
    } catch (_) {
      // Fall through to cache
    }

    // Fall back to cache
    final cached = prefs.getString(_cacheKey);
    if (cached != null) return _parseRecipes(cached);

    return [];
  }

  static List<Recipe> _parseRecipes(String body) {
    final decoded = json.decode(body);

    // Support both formats:
    // 1. Top-level array:       [ { "recipe": {...} }, ... ]
    // 2. Wrapped object:        { "recipes": [ { "recipe": {...} }, ... ] }
    final List<dynamic> data =
        decoded is List ? decoded : (decoded['recipes'] as List<dynamic>);

    return data.map((item) {
      final recipeJson = item['recipe'] ?? item;
      return Recipe.fromJson(recipeJson);
    }).toList();
  }

  // ─── Public API (unchanged from your original) ───────────────────────────────

  static Future<List<Recipe>> getAllRecipes() async => await loadRecipes();

  static Future<List<Recipe>> getTop10Recipes() async {
    final allRecipes = await loadRecipes();
    if (allRecipes.length <= 10) return allRecipes;
    return allRecipes.sublist(0, 10);
  }

  static Future<Recipe?> randomRecipe() async {
    final allRecipes = await loadRecipes();
    if (allRecipes.isEmpty) return null;
    return allRecipes[Random().nextInt(allRecipes.length)];
  }

  static Future<Map<String, Recipe?>> randomMealSet() async {
    final allRecipes = await loadRecipes();
    if (allRecipes.isEmpty) {
      return {'cocktail': null, 'bread': null, 'starter': null,
              'main': null, 'sides': null, 'dessert': null};
    }

    final random = Random();
    Recipe? pickRandom(List<Recipe> list) =>
        list.isNotEmpty ? list[random.nextInt(list.length)] : null;

    final cocktails = allRecipes.where((r) => r.category.toLowerCase() == 'cocktail').toList();
    final breads    = allRecipes.where((r) => r.category.toLowerCase() == 'bread').toList();
    final starters  = allRecipes.where((r) => r.category.toLowerCase() == 'starter').toList();
    final mains     = allRecipes.where((r) => r.category.toLowerCase() == 'main').toList();
    final sides     = allRecipes.where((r) => r.category.toLowerCase() == 'sides').toList();
    final desserts  = allRecipes.where((r) => r.category.toLowerCase() == 'dessert').toList();

    return {
      'cocktail': pickRandom(cocktails),
      'bread':    pickRandom(breads),
      'starter':  pickRandom(starters),
      'main':     pickRandom(mains),
      'sides':    pickRandom(sides),
      'dessert':  pickRandom(desserts),
    };
  }

  static Future<List<Recipe>> searchRecipes(String query) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final allRecipes = await loadRecipes();

    // Strict category mode
    final categories = ['cocktail', 'starter', 'main', 'sides', 'dessert', 'bread'];
    if (categories.contains(lowerQuery)) {
      return allRecipes.where((r) => r.category.toLowerCase() == lowerQuery).toList();
    }

    return allRecipes.where((recipe) {
      bool matchFound =
          recipe.name.toLowerCase().contains(lowerQuery) ||
          recipe.source.toLowerCase().contains(lowerQuery) ||
          recipe.category.toLowerCase().contains(lowerQuery) ||
          recipe.keywords.toLowerCase().contains(lowerQuery) ||
          recipe.chef.toLowerCase().contains(lowerQuery) ||
          recipe.description.toLowerCase().contains(lowerQuery);

      if (!matchFound) {
        matchFound = recipe.ingredients.any((ing) =>
            ing.item.toLowerCase().contains(lowerQuery) ||
            ing.note.toLowerCase().contains(lowerQuery));
      }
      if (!matchFound) {
        matchFound = recipe.specialtools.any((tool) =>
            tool.item.toLowerCase().contains(lowerQuery));
      }
      if (!matchFound) {
        matchFound = recipe.steps.any((step) =>
            step.instruction.toLowerCase().contains(lowerQuery));
      }
      if (!matchFound) {
        for (var sub in recipe.subRecipes) {
          if (sub.name.toLowerCase().contains(lowerQuery) ||
              sub.ingredients.any((i) => i.item.toLowerCase().contains(lowerQuery))) {
            matchFound = true;
            break;
          }
        }
      }
      if (!matchFound) {
        matchFound = _similarity(recipe.name, query) > 0.6 ||
                     _similarity(recipe.chef, query) > 0.6;
      }

      return matchFound;
    }).toList();
  }

  // ─── Fuzzy Helpers (unchanged) ───────────────────────────────────────────────

  static double _similarity(String a, String b) {
    a = a.toLowerCase(); b = b.toLowerCase();
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    int distance = _levenshtein(a, b);
    return 1.0 - (distance / max(a.length, b.length));
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<List<int>> m =
        List.generate(s.length + 1, (_) => List.filled(t.length + 1, 0));
    for (int i = 0; i <= s.length; i++) m[i][0] = i;
    for (int j = 0; j <= t.length; j++) m[0][j] = j;
    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        m[i][j] = [m[i-1][j]+1, m[i][j-1]+1, m[i-1][j-1]+cost].reduce(min);
      }
    }
    return m[s.length][t.length];
  }
}
