class Recipe {
  final String name;
  final String source;
  final String chef;
  final String imageUrl;
  final String yieldInfo;
  final String description;
  final String category;
  final String keywords;
  final List<Ingredient> ingredients;
  final List<StepItem> steps;
  final List<Recipe> subRecipes;

  Recipe({
    required this.name,
    required this.source,
    required this.chef,
    required this.imageUrl,
    required this.yieldInfo,
    required this.description,
    required this.category,
    required this.keywords,
    required this.ingredients,
    required this.steps,
    required this.subRecipes,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'] ?? '',
      source: json['source'] ?? '',
      chef: json['chef'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      yieldInfo: json['yield'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      keywords: json['keywords'] ??'',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((i) => Ingredient.fromJson(i))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((s) => StepItem.fromJson(s))
          .toList(),
      subRecipes: (json['sub_recipes'] as List<dynamic>? ?? [])
          .map((s) => Recipe.fromJson(s))
          .toList(),
    );
  }
}

class Ingredient {
  final String item;
  final String quantity;
  final String note;

  Ingredient({
    required this.item,
    this.quantity = '',
    this.note = '',
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      item: json['item'] ?? '',
      quantity: json['quantity'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

class StepItem {
  final int number;
  final String instruction;

  StepItem({
    required this.number,
    required this.instruction,
  });

  factory StepItem.fromJson(Map<String, dynamic> json) {
    return StepItem(
      number: json['number'] ?? 0,
      instruction: json['instruction'] ?? '',
    );
  }
}


