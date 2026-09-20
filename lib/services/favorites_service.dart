import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';

class FavoritesService {
  FavoritesService._();

  static const String _prefsKey = 'favorite_recipe_slugs';

  /// Reactive set of favorited recipe slugs. Wrap dependent UI in
  /// `ValueListenableBuilder<Set<String>>` rather than polling isFavorite().
  static final ValueNotifier<Set<String>> favoritesNotifier =
      ValueNotifier<Set<String>>(<String>{});

  static bool _loaded = false;

  /// Call once from main(), before runApp, so favoritesNotifier is
  /// populated before any screen reads it. Idempotent.
  static Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    favoritesNotifier.value =
        (prefs.getStringList(_prefsKey) ?? <String>[]).toSet();
    _loaded = true;
  }

  static bool isFavorite(String slug) =>
      favoritesNotifier.value.contains(slug);

  static Future<void> toggleFavorite(String slug) async {
    final updated = Set<String>.from(favoritesNotifier.value);
    if (!updated.remove(slug)) updated.add(slug);
    favoritesNotifier.value = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated.toList());
  }

  /// Cross-references favorited slugs against already-loaded recipes —
  /// favorites are persisted as slugs only, not full recipe JSON.
  static List<Recipe> filterFavorites(List<Recipe> allRecipes) =>
      allRecipes.where((r) => favoritesNotifier.value.contains(r.slug)).toList();
}
