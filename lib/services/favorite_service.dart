import 'package:firebase_database/firebase_database.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/services/database_service.dart';

class FavoriteService {
  final DatabaseService _db = DatabaseService();

  // Add a recipe to user's favorites
  Future<void> addFavorite(String userId, String recipeId) async {
    try {
      await _db.ref('favorites/$userId/recipes/$recipeId').set({
        'recipeId': recipeId,
        'addedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error adding favorite: $e');
      throw Exception('Failed to add to favorites');
    }
  }

  // Remove a recipe from user's favorites
  Future<void> removeFavorite(String userId, String recipeId) async {
    try {
      await _db.ref('favorites/$userId/recipes/$recipeId').remove();
    } catch (e) {
      print('Error removing favorite: $e');
      throw Exception('Failed to remove from favorites');
    }
  }

  // Check if a recipe is in user's favorites
  Future<bool> isFavorite(String userId, String recipeId) async {
    try {
      DatabaseEvent event = await _db.ref('favorites/$userId/recipes/$recipeId').once();
      return event.snapshot.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      throw Exception('Failed to check favorite status');
    }
  }

  // Get all favorite recipes for a user
  Future<List<Recipe>> getUserFavorites(String userId) async {
    try {
      DatabaseEvent event = await _db.ref('favorites/$userId/recipes').orderByChild('addedAt').once();
      if (!event.snapshot.exists) return [];

      Map<dynamic, dynamic> data = event.snapshot.value as Map;
      List<String> recipeIds = [];

      data.forEach((key, value) {
        recipeIds.add(key);
      });

      if (recipeIds.isEmpty) return [];

      // Fetch the actual recipe data
      List<Recipe> recipes = [];

      // Process in batches for better performance
      const batchSize = 10;
      for (var i = 0; i < recipeIds.length; i += batchSize) {
        final end = (i + batchSize < recipeIds.length) ? i + batchSize : recipeIds.length;
        final batch = recipeIds.sublist(i, end);

        for (String id in batch) {
          DatabaseEvent recipeEvent = await _db.ref('recipes/$id').once();
          if (recipeEvent.snapshot.exists) {
            Map<dynamic, dynamic> recipeData = recipeEvent.snapshot.value as Map;
            recipes.add(Recipe.fromMap(Map<String, dynamic>.from(recipeData), id));
          }
        }
      }

      return recipes;
    } catch (e) {
      print('Error getting user favorites: $e');
      throw Exception('Failed to get favorites');
    }
  }

  // Get the count of favorites for a user
  Future<int?> getFavoriteCount(String userId) async {
    try {
      DatabaseEvent event = await _db.ref('favorites/$userId/recipes').once();
      if (!event.snapshot.exists) return 0;

      Map<dynamic, dynamic> data = event.snapshot.value as Map;
      return data.length;
    } catch (e) {
      print('Error getting favorite count: $e');
      throw Exception('Failed to get favorite count');
    }
  }

  // Stream user favorites
  Stream<List<String>> streamUserFavoriteIds(String userId) {
    return _db.ref('favorites/$userId/recipes').onValue.map((event) {
      if (!event.snapshot.exists) return [];

      Map<dynamic, dynamic> data = event.snapshot.value as Map;
      List<String> favoriteIds = [];

      data.forEach((key, value) {
        favoriteIds.add(key);
      });

      return favoriteIds;
    });
  }

  // Get most favorited recipes (for popular recipes section)
  Future<List<Recipe>> getPopularRecipes({int limit = 10}) async {
    try {
      // Get all favorited recipes and their counts
      DatabaseEvent favoritesEvent = await _db.ref('favorites').once();
      if (!favoritesEvent.snapshot.exists) return [];

      // Create a map to count favorites per recipe
      Map<String, int> recipeCounts = {};

      Map<dynamic, dynamic> allUserFavorites = favoritesEvent.snapshot.value as Map;

      // Process each user's favorites
      allUserFavorites.forEach((userId, userData) {
        if (userData != null && userData['recipes'] != null) {
          Map<dynamic, dynamic> userRecipes = userData['recipes'] as Map;
          userRecipes.forEach((recipeId, _) {
            recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
          });
        }
      });

      // Sort recipes by favorite count
      var sortedRecipes = recipeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Take top recipes
      List<String> topRecipeIds = sortedRecipes
          .take(limit)
          .map((e) => e.key)
          .toList();

      if (topRecipeIds.isEmpty) return [];

      // Fetch the actual recipe data
      List<Recipe> recipes = [];

      for (String recipeId in topRecipeIds) {
        DatabaseEvent recipeEvent = await _db.ref('recipes/$recipeId').once();
        if (recipeEvent.snapshot.exists) {
          Map<dynamic, dynamic> recipeData = recipeEvent.snapshot.value as Map;
          recipes.add(Recipe.fromMap(Map<String, dynamic>.from(recipeData), recipeId));
        }
      }

      return recipes;
    } catch (e) {
      print('Error getting popular recipes: $e');
      throw Exception('Failed to get popular recipes');
    }
  }
}