class Recipe {
  final String name;
  final String source;
  final String chef;
  final String imageUrl;
  final String yieldInfo;
  final String description;
  final String category;
  final String keywords;
  final List<WinePairing> winePairings;
  final List<Ingredient> ingredients;
  final List<SpecialTools> specialtools;
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
    required this.winePairings,
    required this.ingredients,
    required this.specialtools,
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
      winePairings: (json["winePairings"] as List<dynamic>? ?? [])
          .map((w) => WinePairing.fromJson(w))
          .toList(),
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((i) => Ingredient.fromJson(i))
          .toList(),
      specialtools: (json['specialtools'] as List<dynamic>? ?? [])
          .map((e) => SpecialTools.fromJson(e))
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

class SpecialTools {
  final String item;
  final String link;

  SpecialTools({
    required this.item,
    required this.link,
  });

  factory SpecialTools.fromJson(Map<String, dynamic> json) {
    return SpecialTools(
      item: json['item'] ?? 0,
      link: json['link'] ?? '',
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

class WinePairing {
  final String name;
  final String notes;

  WinePairing({required this.name, required this.notes});

  factory WinePairing.fromJson(Map<String, dynamic> json) {
    return WinePairing(
      name: json["name"] ?? "",
      notes: json["notes"] ?? "",
    );
  }
}


