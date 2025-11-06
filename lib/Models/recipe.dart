import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Recipe {
  final String dishName;
  final String chef;
  final String source;
  final String url;
  final String cuisine;
  final List<String> tags;
  final List<String> ingredients;
  final List<String> steps;

  Recipe({
    required this.dishName,
    required this.chef,
    required this.source,
    required this.url,
    required this.cuisine,
    required this.tags,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      dishName: json['dish_name'],
      chef: json['chef'],
      source: json['source'],
      url: json['url'],
      cuisine: json['cuisine'],
      tags: List<String>.from(json['tags']),
      ingredients: List<String>.from(json['ingredients']),
      steps: List<String>.from(json['steps']),
    );
  }

  static Future<List<Recipe>> loadRecipes() async {
    final String jsonString = await rootBundle.loadString('assets/recipes.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((item) => Recipe.fromJson(item)).toList();
  }
}
