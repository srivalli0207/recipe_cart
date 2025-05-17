import 'package:firebase_database/firebase_database.dart';

class MealPlan {
  final String id;
  final String userId;
  final DateTime date;
  final List<MealEntry> meals;

  MealPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.meals,
  });

  factory MealPlan.fromMap(Map<String, dynamic> data, String id) {
    return MealPlan(
      id: id,
      userId: data['userId'] ?? '',
      date: data['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['date'])
          : DateTime.now(),
      meals: (data['meals'] as List?)
          ?.map((m) => MealEntry.fromMap(Map<String, dynamic>.from(m)))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'meals': meals.map((m) => m.toMap()).toList(),
    };
  }
}

class MealEntry {
  final String id;
  final String recipeId;
  final String recipeName;
  final String? recipeImageUrl;
  final String mealType; // breakfast, lunch, dinner, snack

  MealEntry({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    this.recipeImageUrl,
    required this.mealType,
  });

  factory MealEntry.fromMap(Map<String, dynamic> data) {
    return MealEntry(
      id: data['id'] ?? '',
      recipeId: data['recipeId'] ?? '',
      recipeName: data['recipeName'] ?? '',
      recipeImageUrl: data['recipeImageUrl'],
      mealType: data['mealType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'recipeImageUrl': recipeImageUrl,
      'mealType': mealType,
    };
  }
}