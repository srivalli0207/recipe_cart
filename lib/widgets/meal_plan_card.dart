import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_cart/models/meal_plan_model.dart';
import 'package:recipe_cart/screens/recipe_detail_screen.dart';

class MealPlanCard extends StatelessWidget {
  final MealEntry mealEntry;
  final VoidCallback onDelete;

  const MealPlanCard({
    Key? key,
    required this.mealEntry,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipeId: mealEntry.recipeId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Meal image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: mealEntry.recipeImageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: mealEntry.recipeImageUrl!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    width: 70,
                    height: 70,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    width: 70,
                    height: 70,
                    child: const Icon(Icons.error),
                  ),
                )
                    : Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[300],
                  child: Icon(
                    _getMealTypeIcon(mealEntry.mealType),
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Meal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal type chip
                    Chip(
                      label: Text(
                        _capitalizeFirst(mealEntry.mealType),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _getMealTypeColor(mealEntry.mealType),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(height: 4),
                    // Recipe name
                    Text(
                      mealEntry.recipeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.red[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.indigo;
      case 'snack':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
