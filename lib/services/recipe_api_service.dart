import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeApiService {
  // You'll need to get a free API key from Spoonacular
  // Visit: https://spoonacular.com/food-api
  static const String _apiKey = 'YOUR_SPOONACULAR_API_KEY';
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';

  // Alternative: Use free APIs (multiple sources)
  static const String _freeApiUrl = 'https://www.themealdb.com/api/json/v1/1';

  // Get recipes by cuisine using Spoonacular API
  Future<List<Map<String, dynamic>>> getRecipesByCuisine(String cuisine, {int limit = 10}) async {
    try {
      // If you have Spoonacular API key
      if (_apiKey != 'YOUR_SPOONACULAR_API_KEY') {
        return await _getSpoonacularRecipes(cuisine, limit);
      } else {
        // Use free MealDB API as fallback
        return await _getMealDBRecipes(cuisine, limit);
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      return [];
    }
  }

  // Spoonacular API implementation
  Future<List<Map<String, dynamic>>> _getSpoonacularRecipes(String cuisine, int limit) async {
    final url = '$_baseUrl/complexSearch'
        '?cuisine=$cuisine'
        '&number=$limit'
        '&addRecipeInformation=true'
        '&addRecipeNutrition=true'
        '&apiKey=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results'] ?? []);
    } else {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }
  }

  // Free MealDB API implementation
  Future<List<Map<String, dynamic>>> _getMealDBRecipes(String cuisine, int limit) async {
    List<Map<String, dynamic>> allRecipes = [];

    // MealDB has different endpoint structure
    String area = _mapCuisineToMealDBArea(cuisine);

    try {
      final url = '$_freeApiUrl/filter.php?a=$area';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> meals = data['meals'] ?? [];

        // Get detailed info for each recipe (limited by API rate limits)
        int count = 0;
        for (var meal in meals) {
          if (count >= limit) break;

          try {
            final detailResponse = await http.get(
                Uri.parse('$_freeApiUrl/lookup.php?i=${meal['idMeal']}')
            );

            if (detailResponse.statusCode == 200) {
              final detailData = json.decode(detailResponse.body);
              if (detailData['meals'] != null && detailData['meals'].isNotEmpty) {
                Map<String, dynamic> convertedRecipe = _convertMealDBToStandard(
                    detailData['meals'][0], cuisine
                );
                allRecipes.add(convertedRecipe);
                count++;
              }
            }

            // Rate limiting - be nice to free API
            await Future.delayed(Duration(milliseconds: 100));
          } catch (e) {
            print('Error getting recipe details: $e');
            continue;
          }
        }
      }
    } catch (e) {
      print('Error fetching from MealDB: $e');
    }

    return allRecipes;
  }

  // Convert MealDB format to standard format
  Map<String, dynamic> _convertMealDBToStandard(Map<String, dynamic> mealData, String cuisine) {
    // Extract ingredients
    List<Map<String, dynamic>> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      String? ingredient = mealData['strIngredient$i'];
      String? measure = mealData['strMeasure$i'];

      if (ingredient != null && ingredient.trim().isNotEmpty) {
        // Parse measure to get quantity and unit
        var parsed = _parseMeasure(measure ?? '1 pcs');
        ingredients.add({
          'name': ingredient.trim(),
          'quantity': parsed['quantity'],
          'unit': parsed['unit'],
        });
      }
    }

    // Extract instructions
    List<String> instructions = [];
    String? instructionText = mealData['strInstructions'];
    if (instructionText != null && instructionText.isNotEmpty) {
      // Split by common delimiters
      instructions = instructionText
          .split(RegExp(r'[\.\r\n]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length > 10)
          .toList();
    }

    return {
      'title': mealData['strMeal'] ?? 'Unnamed Recipe',
      'summary': mealData['strMeal'] ?? '',
      'image': mealData['strMealThumb'] ?? '',
      'readyInMinutes': 30, // Default since MealDB doesn't provide this
      'preparationMinutes': 10,
      'cookingMinutes': 20,
      'servings': 4,
      'cuisines': [cuisine],
      'dishTypes': [_mapMealDBCategory(mealData['strCategory'] ?? '')],
      'vegetarian': false, // MealDB doesn't provide dietary info
      'vegan': false,
      'glutenFree': false,
      'dairyFree': false,
      'extendedIngredients': ingredients.map((ing) => {
        'name': ing['name'],
        'amount': ing['quantity'],
        'unit': ing['unit'],
        'original': '${ing['quantity']} ${ing['unit']} ${ing['name']}',
      }).toList(),
      'instructions': instructions.join('. '),
      'analyzedInstructions': [], // Will be parsed by the main converter
    };
  }

  // Parse measure text to extract quantity and unit
  Map<String, dynamic> _parseMeasure(String measure) {
    measure = measure.trim().toLowerCase();

    // Common patterns
    RegExp numberUnit = RegExp(r'(\d+(?:\.\d+)?)\s*([a-z]+)');
    RegExp fractionUnit = RegExp(r'(\d+/\d+)\s*([a-z]+)');
    RegExp justNumber = RegExp(r'(\d+(?:\.\d+)?)');

    Match? match = numberUnit.firstMatch(measure);
    if (match != null) {
      return {
        'quantity': double.tryParse(match.group(1)!) ?? 1.0,
        'unit': _standardizeUnit(match.group(2)!),
      };
    }

    match = fractionUnit.firstMatch(measure);
    if (match != null) {
      return {
        'quantity': _parseFraction(match.group(1)!),
        'unit': _standardizeUnit(match.group(2)!),
      };
    }

    match = justNumber.firstMatch(measure);
    if (match != null) {
      return {
        'quantity': double.tryParse(match.group(1)!) ?? 1.0,
        'unit': 'pcs',
      };
    }

    return {'quantity': 1.0, 'unit': 'pcs'};
  }

  // Convert fraction to decimal
  double _parseFraction(String fraction) {
    List<String> parts = fraction.split('/');
    if (parts.length == 2) {
      double numerator = double.tryParse(parts[0]) ?? 1.0;
      double denominator = double.tryParse(parts[1]) ?? 1.0;
      return numerator / denominator;
    }
    return 1.0;
  }

  // Standardize unit names
  String _standardizeUnit(String unit) {
    unit = unit.toLowerCase();

    if (unit.contains('cup')) return 'cup';
    if (unit.contains('tbsp') || unit.contains('tablespoon')) return 'tbsp';
    if (unit.contains('tsp') || unit.contains('teaspoon')) return 'tsp';
    if (unit.contains('oz') || unit.contains('ounce')) return 'oz';
    if (unit.contains('lb') || unit.contains('pound')) return 'lb';
    if (unit.contains('g') && !unit.contains('kg')) return 'g';
    if (unit.contains('kg') || unit.contains('kilogram')) return 'kg';
    if (unit.contains('ml') || unit.contains('millilitre')) return 'ml';
    if (unit.contains('l') || unit.contains('litre')) return 'l';
    if (unit.contains('pinch')) return 'pinch';

    return 'pcs'; // Default
  }

  // Map cuisine to MealDB area
  String _mapCuisineToMealDBArea(String cuisine) {
    switch (cuisine.toLowerCase()) {
      case 'italian': return 'Italian';
      case 'mexican': return 'Mexican';
      case 'asian': return 'Chinese'; // Using Chinese as representative
      case 'mediterranean': return 'Greek'; // Using Greek as representative
      case 'american': return 'American';
      case 'indian': return 'Indian';
      case 'french': return 'French';
      default: return 'British'; // Default fallback
    }
  }

  // Map MealDB category to app category
  String _mapMealDBCategory(String category) {
    switch (category.toLowerCase()) {
      case 'starter': return 'appetizer';
      case 'side': return 'side dish';
      case 'dessert': return 'dessert';
      case 'breakfast': return 'breakfast';
      default: return 'dinner';
    }
  }

  // Get random recipes (useful for variety)
  Future<List<Map<String, dynamic>>> getRandomRecipes({int number = 10}) async {
    if (_apiKey != 'YOUR_SPOONACULAR_API_KEY') {
      // Spoonacular random endpoint
      final url = '$_baseUrl/random?number=$number&apiKey=$_apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['recipes'] ?? []);
      }
    } else {
      // MealDB random recipes
      List<Map<String, dynamic>> randomRecipes = [];

      for (int i = 0; i < number; i++) {
        try {
          final response = await http.get(Uri.parse('$_freeApiUrl/random.php'));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['meals'] != null && data['meals'].isNotEmpty) {
              randomRecipes.add(_convertMealDBToStandard(data['meals'][0], 'Various'));
            }
          }
          await Future.delayed(Duration(milliseconds: 100)); // Rate limiting
        } catch (e) {
          print('Error getting random recipe: $e');
          continue;
        }
      }

      return randomRecipes;
    }

    return [];
  }
}