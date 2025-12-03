// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(recipe.imageUrl, fit: BoxFit.cover, height: 180, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(recipe.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(recipe.source,style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}