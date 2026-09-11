import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';

class RecipeService {
  static const String _url = 'https://pub-3ae50d56fa834654954be23601470560.r2.dev/assets/recipes.json'; // 👈 your R2 URL
  static const String _cacheKey = 'cached_recipes';

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

  static Future<List<Recipe>> searchRecipes(String query) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final allRecipes = await loadRecipes();

    // Strict category mode
    final categories = ['cocktail', 'starter', 'brunch', 'main', 'sides', 'dessert', 'bread'];
    if (categories.contains(lowerQuery)) {
      return allRecipes.where((r) => r.category.toLowerCase() == lowerQuery).toList();
    }

    final scored = allRecipes
        .map((r) => MapEntry(r, _relevance(r, lowerQuery, query)))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  // Ranks how relevant a recipe is to a query so that "chicken" surfaces
  // actual chicken dishes before recipes that merely use chicken stock.
  static int _relevance(Recipe recipe, String lowerQuery, String rawQuery) {
    int score = 0;
    final name = recipe.name.toLowerCase();

    if (name == lowerQuery) {
      score += 100;
    } else if (name.startsWith(lowerQuery)) {
      score += 70;
    } else if (name.contains(lowerQuery)) {
      score += 50;
    }

    if (recipe.keywords.toLowerCase().contains(lowerQuery)) score += 40;
    if (recipe.category.toLowerCase().contains(lowerQuery)) score += 30;
    if (recipe.chef.toLowerCase().contains(lowerQuery)) score += 30;
    if (recipe.source.toLowerCase().contains(lowerQuery)) score += 20;
    if (recipe.description.toLowerCase().contains(lowerQuery)) score += 15;

    if (recipe.ingredients.any((ing) =>
        ing.item.toLowerCase().contains(lowerQuery) ||
        ing.note.toLowerCase().contains(lowerQuery))) {
      score += 12;
    }
    if (recipe.specialtools.any((tool) => tool.item.toLowerCase().contains(lowerQuery))) {
      score += 8;
    }
    for (var sub in recipe.subRecipes) {
      if (sub.name.toLowerCase().contains(lowerQuery)) score += 10;
      if (sub.ingredients.any((i) => i.item.toLowerCase().contains(lowerQuery))) score += 6;
    }
    if (recipe.steps.any((step) => step.instruction.toLowerCase().contains(lowerQuery))) {
      score += 5;
    }

    // Typo-tolerant fallback only kicks in when nothing else matched.
    if (score == 0) {
      final sim = max(_similarity(recipe.name, rawQuery), _similarity(recipe.chef, rawQuery));
      if (sim > 0.6) score += (sim * 40).round();
    }

    return score;
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
    for (int i = 0; i <= s.length; i++) {
      m[i][0] = i;
    }
    for (int j = 0; j <= t.length; j++) {
      m[0][j] = j;
    }
    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        m[i][j] = [m[i-1][j]+1, m[i][j-1]+1, m[i-1][j-1]+cost].reduce(min);
      }
    }
    return m[s.length][t.length];
  }
}
