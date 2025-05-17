import 'package:firebase_database/firebase_database.dart';
import 'package:recipe_cart/models/shopping_list_model.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/services/database_service.dart';
import 'package:recipe_cart/services/recipe_service.dart';
import 'package:uuid/uuid.dart';

class ShoppingListService {
  final DatabaseService _db = DatabaseService();
  final RecipeService _recipeService = RecipeService();
  final Uuid _uuid = Uuid();

  // Get shopping list for user
  Stream<List<ShoppingListItem>> getShoppingList(String userId) {
    return _db.ref('users/$userId/shoppingList').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      List<ShoppingListItem> items = [];
      data.forEach((key, value) {
        items.add(ShoppingListItem.fromMap(Map<String, dynamic>.from(value), key));
      });

      return items;
    });
  }

  // Add item to shopping list
  Future<ShoppingListItem?> addShoppingListItem({
    required String userId,
    required String name,
    required double quantity,
    required String unit,
    String? recipeId,
    String? recipeName,
  }) async {
    try {
      String itemId = _uuid.v4();
      ShoppingListItem item = ShoppingListItem(
        id: itemId,
        name: name,
        quantity: quantity,
        unit: unit,
        recipeId: recipeId,
        recipeName: recipeName,
        isChecked: false,
      );

      await _db.ref('users/$userId/shoppingList/$itemId').set(item.toMap());
      return item;
    } catch (e) {
      print('Error adding shopping list item: $e');
      return null;
    }
  }

  // Add ingredients from recipe to shopping list
  Future<bool> addRecipeIngredientsToShoppingList({
    required String userId,
    required Recipe recipe,
    int servings = 1,
  }) async {
    try {
      // Calculate scaling factor if servings is different from recipe default
      double scaleFactor = servings / recipe.servings;

      // Check for existing items
      for (Ingredient ingredient in recipe.ingredients) {
        bool itemExists = false;
        String? existingItemId;
        double existingQuantity = 0;

        // Get existing shopping list to check for duplicates
        DatabaseEvent event = await _db.ref('users/$userId/shoppingList').once();
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> data = event.snapshot.value as Map;
          data.forEach((key, value) {
            Map<String, dynamic> item = Map<String, dynamic>.from(value);
            if (item['name'] == ingredient.name) {
              itemExists = true;
              existingItemId = key;
              existingQuantity = item['quantity'] ?? 0.0;
            }
          });
        }

        if (itemExists && existingItemId != null) {
          // Update existing item quantity
          double newQuantity = existingQuantity + (ingredient.quantity * scaleFactor);
          await _db.ref('users/$userId/shoppingList/$existingItemId').update({
            'quantity': newQuantity
          });
        } else {
          // Add new item
          await addShoppingListItem(
            userId: userId,
            name: ingredient.name,
            quantity: ingredient.quantity * scaleFactor,
            unit: ingredient.unit,
            recipeId: recipe.id,
            recipeName: recipe.name,
          );
        }
      }
      return true;
    } catch (e) {
      print('Error adding recipe to shopping list: $e');
      return false;
    }
  }

  // Update shopping list item
  Future<bool> updateShoppingListItem({
    required String userId,
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.ref('users/$userId/shoppingList/$itemId').update(data);
      return true;
    } catch (e) {
      print('Error updating shopping list item: $e');
      return false;
    }
  }

  // Toggle item checked status
  Future<bool> toggleItemChecked({
    required String userId,
    required String itemId,
    required bool isChecked,
  }) async {
    return updateShoppingListItem(
      userId: userId,
      itemId: itemId,
      data: {'isChecked': isChecked},
    );
  }

  // Remove item from shopping list
  Future<bool> removeShoppingListItem({
    required String userId,
    required String itemId,
  }) async {
    try {
      await _db.ref('users/$userId/shoppingList/$itemId').remove();
      return true;
    } catch (e) {
      print('Error removing shopping list item: $e');
      return false;
    }
  }

  // Clear all checked items
  Future<bool> clearCheckedItems(String userId) async {
    try {
      DatabaseEvent event = await _db.ref('users/$userId/shoppingList').once();
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          Map<String, dynamic> item = Map<String, dynamic>.from(value);
          if (item['isChecked'] == true) {
            _db.ref('users/$userId/shoppingList/$key').remove();
          }
        });
      }
      return true;
    } catch (e) {
      print('Error clearing checked items: $e');
      return false;
    }
  }

  // Clear entire shopping list
  Future<bool> clearShoppingList(String userId) async {
    try {
      await _db.ref('users/$userId/shoppingList').remove();
      return true;
    } catch (e) {
      print('Error clearing shopping list: $e');
      return false;
    }
  }
}