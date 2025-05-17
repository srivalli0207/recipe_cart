import 'package:firebase_database/firebase_database.dart';
import 'package:recipe_cart/models/meal_plan_model.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/services/database_service.dart';
import 'package:recipe_cart/services/recipe_service.dart';
import 'package:uuid/uuid.dart';

class MealPlanService {
  final DatabaseService _db = DatabaseService();
  final RecipeService _recipeService = RecipeService();
  final Uuid _uuid = Uuid();

  // Get meal plans for a specific date range
  Future<List<MealPlan>> getMealPlansForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      // We need to normalize the dates to start and end of day for proper querying
      int start = DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch;
      int end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch;

      // Query meal plans within the date range
      DatabaseEvent event = await _db.ref('users/$userId/mealPlans')
          .orderByChild('date')
          .startAt(start)
          .endAt(end)
          .once();

      if (!event.snapshot.exists) return [];

      Map<dynamic, dynamic> data = event.snapshot.value as Map;
      List<MealPlan> mealPlans = [];

      data.forEach((key, value) {
        mealPlans.add(MealPlan.fromMap(Map<String, dynamic>.from(value), key));
      });

      return mealPlans;
    } catch (e) {
      print('Error getting meal plans: $e');
      return [];
    }
  }

  // Get meal plan for a specific date
  Future<MealPlan?> getMealPlanForDate(String userId, DateTime date) async {
    try {
      // Normalize date to start of day
      int normalizedDate = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

      // Query for meal plan on this date
      DatabaseEvent event = await _db.ref('users/$userId/mealPlans')
          .orderByChild('date')
          .equalTo(normalizedDate)
          .once();

      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        String key = data.keys.first;
        return MealPlan.fromMap(Map<String, dynamic>.from(data[key]), key);
      }

      // If no meal plan exists, create an empty one
      return await createMealPlan(userId, date);
    } catch (e) {
      print('Error getting meal plan for date: $e');
      return null;
    }
  }

  // Create a new meal plan
  Future<MealPlan> createMealPlan(String userId, DateTime date) async {
    try {
      // Normalize date to start of day
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      int normalizedTimestamp = normalizedDate.millisecondsSinceEpoch;

      String mealPlanId = _uuid.v4();
      MealPlan mealPlan = MealPlan(
        id: mealPlanId,
        userId: userId,
        date: normalizedDate,
        meals: [],
      );

      Map<String, dynamic> mealPlanMap = mealPlan.toMap();
      // Convert DateTime to timestamp for Firebase
      mealPlanMap['date'] = normalizedTimestamp;

      await _db.ref('users/$userId/mealPlans/$mealPlanId').set(mealPlanMap);
      return mealPlan;
    } catch (e) {
      print('Error creating meal plan: $e');
      throw e;
    }
  }

  // Add meal to meal plan
  Future<bool> addMealToMealPlan({
    required String userId,
    required String mealPlanId,
    required String recipeId,
    required String mealType,
  }) async {
    try {
      // Get recipe details
      Recipe? recipe = await _recipeService.getRecipeById(recipeId);
      if (recipe == null) return false;

      // Create meal entry
      MealEntry mealEntry = MealEntry(
        id: _uuid.v4(),
        recipeId: recipeId,
        recipeName: recipe.name,
        recipeImageUrl: recipe.imageUrl,
        mealType: mealType,
      );

      // Get current meal plan
      DatabaseEvent mealPlanEvent = await _db.ref('users/$userId/mealPlans/$mealPlanId').once();
      if (!mealPlanEvent.snapshot.exists) return false;

      Map<dynamic, dynamic> mealPlanData = mealPlanEvent.snapshot.value as Map;
      List<dynamic> currentMeals = mealPlanData['meals'] ?? [];

      // Add new meal to the list
      List<Map<String, dynamic>> updatedMeals = [
        ...currentMeals.map((m) => Map<String, dynamic>.from(m)),
        mealEntry.toMap()
      ];

      // Update meal plan in database
      await _db.ref('users/$userId/mealPlans/$mealPlanId').update({
        'meals': updatedMeals
      });

      return true;
    } catch (e) {
      print('Error adding meal to meal plan: $e');
      return false;
    }
  }

  // Remove meal from meal plan
  Future<bool> removeMealFromMealPlan({
    required String userId,
    required String mealPlanId,
    required String mealEntryId,
  }) async {
    try {
      // Get current meal plan
      DatabaseEvent mealPlanEvent = await _db.ref('users/$userId/mealPlans/$mealPlanId').once();
      if (!mealPlanEvent.snapshot.exists) return false;

      Map<dynamic, dynamic> mealPlanData = mealPlanEvent.snapshot.value as Map;
      List<dynamic> currentMeals = mealPlanData['meals'] ?? [];

      // Filter out the meal to remove
      List<Map<String, dynamic>> updatedMeals = [];
      for (var meal in currentMeals) {
        Map<String, dynamic> mealMap = Map<String, dynamic>.from(meal);
        if (mealMap['id'] != mealEntryId) {
          updatedMeals.add(mealMap);
        }
      }

      // Update meal plan in database
      await _db.ref('users/$userId/mealPlans/$mealPlanId').update({
        'meals': updatedMeals
      });

      return true;
    } catch (e) {
      print('Error removing meal from meal plan: $e');
      return false;
    }
  }

  // Generate shopping list from meal plan for date range
  Future<bool> generateShoppingListFromMealPlan({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get meal plans for date range
      List<MealPlan> mealPlans = await getMealPlansForDateRange(
          userId, startDate, endDate);

      // Collect all recipe IDs from meal plans
      Set<String> recipeIds = {};
      for (var mealPlan in mealPlans) {
        for (var meal in mealPlan.meals) {
          recipeIds.add(meal.recipeId);
        }
      }

      // Get all recipes
      List<Recipe> recipes = [];
      for (String recipeId in recipeIds) {
        Recipe? recipe = await _recipeService.getRecipeById(recipeId);
        if (recipe != null) {
          recipes.add(recipe);
        }
      }

      // Clear existing shopping list first
      await _db.ref('users/$userId/shoppingList').remove();

      // Add all ingredients to shopping list
      Map<String, Map<String, dynamic>> consolidatedIngredients = {};

      for (Recipe recipe in recipes) {
        for (Ingredient ingredient in recipe.ingredients) {
          String key = ingredient.name.toLowerCase();
          if (consolidatedIngredients.containsKey(key)) {
            // Ingredient already exists, update quantity
            consolidatedIngredients[key]!['quantity'] += ingredient.quantity;
          } else {
            // New ingredient
            consolidatedIngredients[key] = {
              'name': ingredient.name,
              'quantity': ingredient.quantity,
              'unit': ingredient.unit,
              'isChecked': false,
            };
          }
        }
      }

      // Add consolidated ingredients to shopping list
      for (var entry in consolidatedIngredients.entries) {
        String itemId = _uuid.v4();
        await _db.ref('users/$userId/shoppingList/$itemId').set(entry.value);
      }

      return true;
    } catch (e) {
      print('Error generating shopping list from meal plan: $e');
      return false;
    }
  }
}