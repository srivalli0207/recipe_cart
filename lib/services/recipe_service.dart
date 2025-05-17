import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/models/review_model.dart';
import 'package:recipe_cart/services/database_service.dart';
import 'package:uuid/uuid.dart';

class RecipeService {
  final DatabaseService _db = DatabaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  // Default image URL - you can replace this with your own default image
  static const String DEFAULT_RECIPE_IMAGE = 'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=Recipe+Image';

  // Get all recipes
  Stream<List<Recipe>> get recipes {
    return _db.ref('recipes').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      List<Recipe> recipeList = [];
      data.forEach((key, value) {
        recipeList.add(Recipe.fromMap(Map<String, dynamic>.from(value), key));
      });

      // Sort by createdDate in descending order
      recipeList.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return recipeList;
    });
  }

  // Get recipes by category
  Stream<List<Recipe>> getRecipesByCategory(String category) {
    return _db.ref('recipes').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      List<Recipe> recipeList = [];
      data.forEach((key, value) {
        Map<String, dynamic> recipeData = Map<String, dynamic>.from(value);
        List<dynamic> categories = recipeData['categories'] ?? [];
        if (categories.contains(category)) {
          recipeList.add(Recipe.fromMap(recipeData, key));
        }
      });

      return recipeList;
    });
  }

  // Get recipes by cuisine
  Stream<List<Recipe>> getRecipesByCuisine(String cuisine) {
    return _db.ref('recipes').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      List<Recipe> recipeList = [];
      data.forEach((key, value) {
        Map<String, dynamic> recipeData = Map<String, dynamic>.from(value);
        if (recipeData['cuisineType'] == cuisine) {
          recipeList.add(Recipe.fromMap(recipeData, key));
        }
      });

      return recipeList;
    });
  }

  // Get recipes by dietary preferences
  Stream<List<Recipe>> getRecipesByDietaryPreference(String preference) {
    return _db.ref('recipes').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      List<Recipe> recipeList = [];
      data.forEach((key, value) {
        Map<String, dynamic> recipeData = Map<String, dynamic>.from(value);
        Map<String, dynamic> dietaryInfo = Map<String, dynamic>.from(recipeData['dietaryInfo'] ?? {});
        if (dietaryInfo[preference] == true) {
          recipeList.add(Recipe.fromMap(recipeData, key));
        }
      });

      return recipeList;
    });
  }

  // Get recipes by cooking time
  Stream<List<Recipe>> getRecipesByCookingTime(int maxMinutes) {
    return _db.ref('recipes').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      List<Recipe> recipeList = [];
      data.forEach((key, value) {
        Map<String, dynamic> recipeData = Map<String, dynamic>.from(value);
        int cookTime = recipeData['cookTimeMinutes'] ?? 0;
        if (cookTime <= maxMinutes) {
          recipeList.add(Recipe.fromMap(recipeData, key));
        }
      });

      return recipeList;
    });
  }

  // Get recipes by author
  Stream<List<Recipe>> getRecipesByAuthor(String authorId) {
    return _db.ref('recipes').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      List<Recipe> recipeList = [];
      data.forEach((key, value) {
        Map<String, dynamic> recipeData = Map<String, dynamic>.from(value);
        if (recipeData['authorId'] == authorId) {
          recipeList.add(Recipe.fromMap(recipeData, key));
        }
      });

      return recipeList;
    });
  }

  // Get recipe by id
  Future<Recipe?> getRecipeById(String id) async {
    try {
      DatabaseEvent event = await _db.ref('recipes/$id').once();
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return Recipe.fromMap(Map<String, dynamic>.from(data), id);
      }
      return null;
    } catch (e) {
      print('Error getting recipe by id: $e');
      return null;
    }
  }

  // Add a new recipe - Modified to handle optional images
  Future<Recipe?> addRecipe({
    required String name,
    required String description,
    required String authorId,
    required String authorName,
    File? imageFile, // Changed from required File to nullable File?
    required List<Ingredient> ingredients,
    required List<String> instructions,
    required int prepTimeMinutes,
    required int cookTimeMinutes,
    required int servings,
    required List<String> categories,
    required String cuisineType,
    required Map<String, bool> dietaryInfo,
    required NutritionalInfo nutritionalInfo,
  }) async {
    try {
      String imageUrl = DEFAULT_RECIPE_IMAGE; // Default image URL

      // Upload image to Firebase Storage only if imageFile is provided
      if (imageFile != null) {
        try {
          String fileName = '${_uuid.v4()}.jpg';
          Reference storageRef = _storage.ref().child('recipe_images/$fileName');
          UploadTask uploadTask = storageRef.putFile(imageFile);
          TaskSnapshot snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
          print('Image uploaded successfully: $imageUrl');
        } catch (imageError) {
          print('Error uploading image: $imageError');
          // Continue with default image if upload fails
          print('Using default image instead');
        }
      } else {
        print('No image provided, using default image');
      }

      // Create recipe document
      String recipeId = _uuid.v4();
      Recipe recipe = Recipe(
        id: recipeId,
        name: name,
        description: description,
        authorId: authorId,
        authorName: authorName,
        imageUrl: imageUrl, // Will be either uploaded image URL or default
        ingredients: ingredients,
        instructions: instructions,
        prepTimeMinutes: prepTimeMinutes,
        cookTimeMinutes: cookTimeMinutes,
        servings: servings,
        categories: categories,
        cuisineType: cuisineType,
        dietaryInfo: dietaryInfo,
        nutritionalInfo: nutritionalInfo,
        rating: 0.0,
        reviewCount: 0,
        createdDate: DateTime.now(),
      );

      // Save to Firebase Realtime Database
      await _db.ref('recipes/$recipeId').set(recipe.toMap());
      print('Recipe saved successfully with ID: $recipeId');
      return recipe;
    } catch (e) {
      print('Error adding recipe: $e');
      return null;
    }
  }

  // Update a recipe
  Future<bool> updateRecipe({
    required String id,
    required Map<String, dynamic> data,
    File? newImageFile,
  }) async {
    try {
      // If there's a new image, upload it
      if (newImageFile != null) {
        String fileName = '${_uuid.v4()}.jpg';
        Reference storageRef = _storage.ref().child('recipe_images/$fileName');
        UploadTask uploadTask = storageRef.putFile(newImageFile);
        TaskSnapshot snapshot = await uploadTask;
        String imageUrl = await snapshot.ref.getDownloadURL();
        data['imageUrl'] = imageUrl;
      }

      await _db.ref('recipes/$id').update(data);
      return true;
    } catch (e) {
      print('Error updating recipe: $e');
      return false;
    }
  }

  // Delete a recipe
  Future<bool> deleteRecipe(String id) async {
    try {
      // Get the recipe to find the image URL
      DatabaseEvent event = await _db.ref('recipes/$id').once();
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        String imageUrl = data['imageUrl'] ?? '';

        // Delete the image from storage if it exists and is not the default image
        if (imageUrl.isNotEmpty && imageUrl != DEFAULT_RECIPE_IMAGE) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            print('Error deleting image: $e');
            // Continue with recipe deletion even if image deletion fails
          }
        }
      }

      // Delete the recipe
      await _db.ref('recipes/$id').remove();

      // Delete associated reviews
      await _db.ref('reviews').orderByChild('recipeId').equalTo(id).once().then((event) {
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> data = event.snapshot.value as Map;
          data.forEach((key, value) {
            _db.ref('reviews/$key').remove();
          });
        }
      });

      return true;
    } catch (e) {
      print('Error deleting recipe: $e');
      return false;
    }
  }

  // Add a review
  Future<Review?> addReview({
    required String recipeId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required double rating,
    required String comment,
  }) async {
    try {
      // Create review
      String reviewId = _uuid.v4();
      Review review = Review(
        id: reviewId,
        recipeId: recipeId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        rating: rating,
        comment: comment,
        date: DateTime.now(),
      );

      // Add review to database
      await _db.ref('reviews/$reviewId').set(review.toMap());

      // Update recipe rating and review count
      DatabaseEvent recipeEvent = await _db.ref('recipes/$recipeId').once();
      if (recipeEvent.snapshot.exists) {
        Map<dynamic, dynamic> recipeData = recipeEvent.snapshot.value as Map;
        int currentReviewCount = recipeData['reviewCount'] ?? 0;
        double currentRating = recipeData['rating'] ?? 0.0;

        // Calculate new average rating
        double totalRatingPoints = currentRating * currentReviewCount;
        int newReviewCount = currentReviewCount + 1;
        double newRating = (totalRatingPoints + rating) / newReviewCount;

        // Update recipe
        await _db.ref('recipes/$recipeId').update({
          'rating': newRating,
          'reviewCount': newReviewCount,
        });
      }

      return review;
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  // Get reviews for a recipe
  Stream<List<Review>> getReviewsForRecipe(String recipeId) {
    return _db.ref('reviews').orderByChild('recipeId').equalTo(recipeId).onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      List<Review> reviewList = [];
      data.forEach((key, value) {
        reviewList.add(Review.fromMap(Map<String, dynamic>.from(value), key));
      });

      // Sort by date in descending order
      reviewList.sort((a, b) => b.date.compareTo(a.date));
      return reviewList;
    });
  }

  // Search recipes by name
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      DatabaseEvent event = await _db.ref('recipes').once();
      if (!event.snapshot.exists) return [];

      Map<dynamic, dynamic> data = event.snapshot.value as Map;

      List<Recipe> searchResults = [];
      data.forEach((key, value) {
        Map<String, dynamic> recipeData = Map<String, dynamic>.from(value);
        String name = recipeData['name'] ?? '';
        String description = recipeData['description'] ?? '';

        if (name.toLowerCase().contains(query.toLowerCase()) ||
            description.toLowerCase().contains(query.toLowerCase())) {
          searchResults.add(Recipe.fromMap(recipeData, key));
        }
      });

      return searchResults;
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  Future<bool> deleteReview({
    required String reviewId,
    required String recipeId,
    required double reviewRating,
  }) async {
    try {
      print('Starting to delete review: $reviewId for recipe: $recipeId');

      // First, check if the review exists
      DatabaseEvent reviewEvent = await _db.ref('reviews/$reviewId').once();
      if (!reviewEvent.snapshot.exists) {
        print('Review not found: $reviewId');
        return false;
      }

      // Get the current recipe data to update rating
      DatabaseEvent recipeEvent = await _db.ref('recipes/$recipeId').once();
      if (!recipeEvent.snapshot.exists) {
        print('Recipe not found: $recipeId');
        return false;
      }

      Map<dynamic, dynamic> recipeData = recipeEvent.snapshot.value as Map;
      int currentReviewCount = recipeData['reviewCount'] ?? 0;
      double currentRating = (recipeData['rating'] ?? 0.0).toDouble();

      print('Current rating: $currentRating, Review count: $currentReviewCount');
      print('Review to delete rating: $reviewRating');

      // Delete the review first
      await _db.ref('reviews/$reviewId').remove();
      print('Review deleted successfully');

      // Update recipe rating and review count
      if (currentReviewCount > 1) {
        // Calculate new average rating after removing this review
        double totalRatingPoints = currentRating * currentReviewCount;
        double newTotalRating = totalRatingPoints - reviewRating;
        int newReviewCount = currentReviewCount - 1;
        double newRating = newTotalRating / newReviewCount;

        // Ensure rating doesn't go below 0
        newRating = newRating < 0 ? 0 : newRating;

        print('New rating: $newRating, New review count: $newReviewCount');

        await _db.ref('recipes/$recipeId').update({
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'reviewCount': newReviewCount,
        });
      } else {
        // This was the last review, reset to 0
        print('Last review deleted, resetting to 0');
        await _db.ref('recipes/$recipeId').update({
          'rating': 0.0,
          'reviewCount': 0,
        });
      }

      print('Recipe updated successfully');
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
}