import 'package:flutter/material.dart';
import 'package:recipe_cart/models/recipe_model.dart';

class IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final int servings;
  final int defaultServings;

  const IngredientTile({
    Key? key,
    required this.ingredient,
    required this.servings,
    required this.defaultServings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate adjusted quantity based on servings
    final double adjustedQuantity = ingredient.quantity * (servings / defaultServings);
    final String displayQuantity = adjustedQuantity % 1 == 0
        ? adjustedQuantity.toInt().toString()
        : adjustedQuantity.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              ingredient.name,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            '$displayQuantity ${ingredient.unit}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}