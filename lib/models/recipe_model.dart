import 'package:firebase_database/firebase_database.dart';

class Recipe {
  final String id;
  final String name;
  final String description;
  final String authorId;
  final String authorName;
  final String imageUrl;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final List<String> categories;
  final String cuisineType;
  final Map<String, bool> dietaryInfo;
  final NutritionalInfo nutritionalInfo;
  final double rating;
  final int reviewCount;
  final DateTime createdDate;
  final bool isApiRecipe;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.categories,
    required this.cuisineType,
    required this.dietaryInfo,
    required this.nutritionalInfo,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdDate,
    this.isApiRecipe = false,
  });

  factory Recipe.fromMap(Map<String, dynamic> data, String id) {
    return Recipe(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ingredients: _ingredientsFromList(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      prepTimeMinutes: data['prepTimeMinutes'] ?? 0,
      cookTimeMinutes: data['cookTimeMinutes'] ?? 0,
      servings: data['servings'] ?? 1,
      categories: List<String>.from(data['categories'] ?? []),
      cuisineType: data['cuisineType'] ?? '',
      dietaryInfo: Map<String, bool>.from(data['dietaryInfo'] ?? {}),
      nutritionalInfo: NutritionalInfo.fromMap(
          Map<String, dynamic>.from(data['nutritionalInfo'] ?? {})),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdDate: data['createdDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdDate'])
          : DateTime.now(),
      isApiRecipe: data['isApiRecipe'] ?? false,
    );
  }

  static List<Ingredient> _ingredientsFromList(List<dynamic> list) {
    return list.map((item) =>
        Ingredient.fromMap(Map<String, dynamic>.from(item))
    ).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'instructions': instructions,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'categories': categories,
      'cuisineType': cuisineType,
      'dietaryInfo': dietaryInfo,
      'nutritionalInfo': nutritionalInfo.toMap(),
      'rating': rating,
      'reviewCount': reviewCount,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'isApiRecipe': isApiRecipe,
    };
  }
}

class Ingredient {
  final String name;
  final double quantity;
  final String unit;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory Ingredient.fromMap(Map<String, dynamic> data) {
    return Ingredient(
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class NutritionalInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;

  NutritionalInfo({
    this.calories = 0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.sugar = 0.0,
    this.fiber = 0.0,
  });

  factory NutritionalInfo.fromMap(Map<String, dynamic> data) {
    return NutritionalInfo(
      calories: data['calories'] ?? 0,
      protein: (data['protein'] ?? 0.0).toDouble(),
      carbs: (data['carbs'] ?? 0.0).toDouble(),
      fat: (data['fat'] ?? 0.0).toDouble(),
      sugar: (data['sugar'] ?? 0.0).toDouble(),
      fiber: (data['fiber'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
    };
  }
}