import 'package:firebase_database/firebase_database.dart';
import 'package:recipe_cart/services/recipe_api_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseInitializer {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final Uuid _uuid = Uuid();
  final RecipeApiService _apiService = RecipeApiService();

  // Check if API recipes have been loaded AND verify in database
  Future<bool> isApiDataInitialized() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool prefsCheck = prefs.getBool('api_recipes_loaded') ?? false;

    // Also check if there are actually API recipes in the database
    try {
      DatabaseEvent event = await _database.ref('recipes').orderByChild('authorId').equalTo('api').limitToFirst(1).once();
      bool hasApiRecipes = event.snapshot.exists;

      print('Prefs check: $prefsCheck, Has API recipes: $hasApiRecipes');

      return prefsCheck && hasApiRecipes;
    } catch (e) {
      print('Error checking API recipes: $e');
      return false;
    }
  }

  // Mark API data as initialized
  Future<void> markApiDataAsInitialized() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('api_recipes_loaded', true);
  }

  // Reset API loading status (for testing)
  Future<void> resetApiLoading() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('api_recipes_loaded', false);
    print('API loading status reset');
  }

  // Initialize database with API recipes
  Future<void> initializeDatabase() async {
    try {
      // Load API recipes in background (don't block app startup)
      _loadApiRecipesInBackground();
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  // Force load API recipes (for manual triggering)
  Future<void> forceLoadApiRecipes() async {
    await resetApiLoading();
    await _loadApiRecipesInBackground();
  }

  // Load API recipes in background
  Future<void> _loadApiRecipesInBackground() async {
    if (await isApiDataInitialized()) {
      print('API recipes already loaded, skipping...');
      return;
    }

    try {
      print('Starting to load recipes from API...');

      // Get recipes from multiple cuisines
      List<String> cuisines = ['Italian', 'Mexican', 'American', 'Chinese', 'Indian'];
      int totalLoaded = 0;

      for (String cuisine in cuisines) {
        try {
          print('Loading $cuisine recipes...');
          List<Map<String, dynamic>> apiRecipes = await _apiService.getRecipesByCuisine(cuisine, limit: 3);

          for (var apiRecipe in apiRecipes) {
            String recipeId = _uuid.v4();

            // Convert API recipe to your format
            Map<String, dynamic> convertedRecipe = _convertApiRecipe(apiRecipe);

            await _database.ref('recipes/$recipeId').set(convertedRecipe);
            totalLoaded++;

            // Small delay to avoid overwhelming the API
            await Future.delayed(Duration(milliseconds: 500));
          }

          print('Loaded ${apiRecipes.length} recipes for $cuisine cuisine');
        } catch (e) {
          print('Error loading $cuisine recipes: $e');
          continue; // Continue with other cuisines even if one fails
        }
      }

      if (totalLoaded > 0) {
        await markApiDataAsInitialized();
        print('Successfully loaded $totalLoaded API recipes!');
      } else {
        print('No API recipes were loaded');
      }
    } catch (e) {
      print('Error loading API recipes: $e');
    }
  }

  // Convert API recipe to your app's format
  Map<String, dynamic> _convertApiRecipe(Map<String, dynamic> apiRecipe) {
    // Extract ingredients
    List<Map<String, dynamic>> ingredients = [];
    if (apiRecipe['extendedIngredients'] != null) {
      for (var ingredient in apiRecipe['extendedIngredients']) {
        ingredients.add({
          'name': ingredient['name'] ?? ingredient['original'] ?? '',
          'quantity': (ingredient['amount'] ?? 1.0).toDouble(),
          'unit': ingredient['unit'] ?? 'pcs',
        });
      }
    }

    // Extract instructions
    List<String> instructions = [];
    if (apiRecipe['instructions'] != null && apiRecipe['instructions'].isNotEmpty) {
      // If instructions are provided as a string, split by periods or numbers
      String instructionText = apiRecipe['instructions'];
      // Split by numbered steps or sentences
      instructions = instructionText
          .split(RegExp(r'(\d+\.|<ol>|<li>)'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length > 10)
          .toList();
    } else if (apiRecipe['analyzedInstructions'] != null) {
      // Handle structured instructions
      for (var stepGroup in apiRecipe['analyzedInstructions']) {
        if (stepGroup['steps'] != null) {
          for (var step in stepGroup['steps']) {
            if (step['step'] != null) {
              instructions.add(step['step']);
            }
          }
        }
      }
    }

    // If no instructions found, add a default message
    if (instructions.isEmpty) {
      instructions = ['Instructions not available for this recipe.'];
    }

    // Determine categories based on dish types
    List<String> categories = [];
    if (apiRecipe['dishTypes'] != null) {
      List<dynamic> dishTypes = apiRecipe['dishTypes'];
      for (var type in dishTypes) {
        String category = _mapDishTypeToCategory(type.toString());
        if (category.isNotEmpty && !categories.contains(category)) {
          categories.add(category);
        }
      }
    }
    if (categories.isEmpty) categories = ['Dinner']; // Default category

    // Determine cuisine type
    String cuisineType = 'Other';
    if (apiRecipe['cuisines'] != null && apiRecipe['cuisines'].isNotEmpty) {
      cuisineType = apiRecipe['cuisines'][0];
    }

    // Extract dietary information
    Map<String, bool> dietaryInfo = {
      'Vegetarian': apiRecipe['vegetarian'] ?? false,
      'Vegan': apiRecipe['vegan'] ?? false,
      'Gluten-Free': apiRecipe['glutenFree'] ?? false,
      'Dairy-Free': apiRecipe['dairyFree'] ?? false,
      'Keto': apiRecipe['ketogenic'] ?? false,
      'Paleo': apiRecipe['whole30'] ?? false,
      'Low-Carb': false, // Not directly available from API
      'Nut-Free': false, // Not directly available from API
    };

    // Extract nutritional info
    Map<String, dynamic> nutritionalInfo = {
      'calories': 0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'sugar': 0.0,
      'fiber': 0.0,
    };

    if (apiRecipe['nutrition'] != null && apiRecipe['nutrition']['nutrients'] != null) {
      for (var nutrient in apiRecipe['nutrition']['nutrients']) {
        String name = nutrient['name'].toLowerCase();
        double amount = (nutrient['amount'] ?? 0.0).toDouble();

        if (name.contains('calories')) nutritionalInfo['calories'] = amount.toInt();
        else if (name.contains('protein')) nutritionalInfo['protein'] = amount;
        else if (name.contains('carbohydrates')) nutritionalInfo['carbs'] = amount;
        else if (name.contains('fat')) nutritionalInfo['fat'] = amount;
        else if (name.contains('sugar')) nutritionalInfo['sugar'] = amount;
        else if (name.contains('fiber')) nutritionalInfo['fiber'] = amount;
      }
    }

    return {
      'name': apiRecipe['title'] ?? 'Unnamed Recipe',
      'description': _cleanHtml(apiRecipe['summary'] ?? apiRecipe['title'] ?? ''),
      'authorId': 'api',
      'authorName': 'Recipe Database',
      'imageUrl': apiRecipe['image'] ?? '',
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTimeMinutes': apiRecipe['preparationMinutes'] ?? 15,
      'cookTimeMinutes': apiRecipe['cookingMinutes'] ?? apiRecipe['readyInMinutes'] ?? 30,
      'servings': apiRecipe['servings'] ?? 4,
      'categories': categories,
      'cuisineType': cuisineType,
      'dietaryInfo': dietaryInfo,
      'nutritionalInfo': nutritionalInfo,
      'rating': 0.0,
      'reviewCount': 0,
      'createdDate': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Map API dish types to app categories
  String _mapDishTypeToCategory(String dishType) {
    dishType = dishType.toLowerCase();

    if (dishType.contains('breakfast') || dishType.contains('morning meal')) return 'Breakfast';
    if (dishType.contains('lunch') || dishType.contains('main course')) return 'Lunch';
    if (dishType.contains('dinner') || dishType.contains('main dish')) return 'Dinner';
    if (dishType.contains('dessert') || dishType.contains('sweet')) return 'Dessert';
    if (dishType.contains('appetizer') || dishType.contains('starter')) return 'Appetizer';
    if (dishType.contains('snack')) return 'Snack';
    if (dishType.contains('side dish') || dishType.contains('side')) return 'Side Dish';
    if (dishType.contains('drink') || dishType.contains('beverage')) return 'Drink';

    return '';
  }

  // Clean HTML tags from text
  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}