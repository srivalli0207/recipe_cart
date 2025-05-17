import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/models/review_model.dart';
import 'package:recipe_cart/screens/recipe/edit_recipe_screen.dart';
import 'package:recipe_cart/services/recipe_service.dart';
import 'package:recipe_cart/services/shopping_list_service.dart';
import 'package:recipe_cart/services/favorite_service.dart';
import 'package:recipe_cart/widgets/review_card.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, bool> checkedIngredients = {};
  int servings = 1;
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 0;
  bool _isSubmittingReview = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty || _userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide both a rating and a comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    final recipeService = Provider.of<RecipeService>(context, listen: false);
    final user = Provider.of<UserModel>(context, listen: false);

    try {
      await recipeService.addReview(
        recipeId: widget.recipeId,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userPhotoUrl: user.photoUrl,
        rating: _userRating,
        comment: _reviewController.text.trim(),
      );

      _reviewController.clear();
      setState(() {
        _userRating = 0;
        _isSubmittingReview = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmittingReview = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteRecipe(BuildContext context, String recipeId, String recipeName) async {
    // Prevent multiple delete attempts
    if (_isDeleting) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "$recipeName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Return if user canceled
    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      final success = await recipeService.deleteRecipe(recipeId);

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to previous screen
        Navigator.pop(context, true); // Pass true to indicate deletion
      } else {
        setState(() {
          _isDeleting = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete recipe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      setState(() {
        _isDeleting = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting recipe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeService = Provider.of<RecipeService>(context);
    final shoppingListService = Provider.of<ShoppingListService>(context);
    final favoriteService = Provider.of<FavoriteService>(context);
    final user = Provider.of<UserModel>(context);

    return FutureBuilder<Recipe?>(
      future: recipeService.getRecipeById(widget.recipeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Recipe not found')),
          );
        }

        final recipe = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(recipe.name),
            actions: [
             if (recipe.authorId == user.uid && !recipe.isApiRecipe) ...[
              if (recipe.authorId == user.uid)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Recipe',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditRecipeScreen(recipe: recipe),
                      ),
                    );

                    // If recipe was updated, refresh the current screen
                    if (result == true) {
                      setState(() {
                        // This will rebuild the UI and fetch the updated recipe
                      });
                    }
                  },
                ),

              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete Recipe',
                onPressed: _isDeleting
                    ? null
                    : () => _confirmDeleteRecipe(context, recipe.id, recipe.name),
              ),

              IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                tooltip: 'Add all ingredients to shopping list',
                onPressed: () async {
                  await shoppingListService.addRecipeIngredientsToShoppingList(
                    userId: user.uid,
                    recipe: recipe,
                    servings: servings,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingredients added to shopping list')),
                  );
                },
              ),
             ],
              // Favorite button
              FutureBuilder<bool>(
                future: favoriteService.isFavorite(user.uid, widget.recipeId),
                builder: (context, snapshot) {
                  bool isFavorite = snapshot.data ?? false;

                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                    onPressed: () async {
                      try {
                        if (isFavorite) {
                          await favoriteService.removeFavorite(user.uid, widget.recipeId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${recipe.name} removed from favorites'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          await favoriteService.addFavorite(user.uid, widget.recipeId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${recipe.name} added to favorites'),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'View Favorites',
                                onPressed: () {
                                  Navigator.pushNamed(context, '/favorites');
                                },
                              ),
                            ),
                          );
                        }
                        // Rebuild the widget to show updated favorite status
                        setState(() {});
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating favorites: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // Recipe Image
              SliverAppBar(
                expandedHeight: 200,
                pinned: false,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 60),
                    ),
                  ),
                ),
              ),

              // Recipe Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe Name and Rating
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: recipe.rating,
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 20.0,
                          ),
                          const SizedBox(width: 8),
                          Text('${recipe.rating.toStringAsFixed(1)} (${recipe.reviewCount} reviews)'),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        recipe.description,
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 24),

                      // Recipe Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                                    const SizedBox(height: 8),
                                    Text('Prep Time', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${recipe.prepTimeMinutes} min'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.timer, color: Theme.of(context).primaryColor),
                                    const SizedBox(height: 8),
                                    Text('Cook Time', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${recipe.cookTimeMinutes} min'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.people, color: Theme.of(context).primaryColor),
                                    const SizedBox(height: 8),
                                    Text('Servings', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${recipe.servings}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Serving size adjuster
                      Row(
                        children: [
                          const Text(
                            'Servings: ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: servings > 1 ? () {
                              setState(() => servings--);
                            } : null,
                          ),
                          Text('$servings', style: const TextStyle(fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() => servings++);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Ingredients Section
                      const Text(
                        'Ingredients',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      ...recipe.ingredients.map((ingredient) {
                        final scaleFactor = servings / recipe.servings;
                        final adjustedQuantity = ingredient.quantity * scaleFactor;
                        final displayQuantity = adjustedQuantity % 1 == 0
                            ? adjustedQuantity.toInt().toString()
                            : adjustedQuantity.toStringAsFixed(1);

                        return CheckboxListTile(
                          title: Text(ingredient.name),
                          subtitle: Text('$displayQuantity ${ingredient.unit}'),
                          value: checkedIngredients[ingredient.name] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              checkedIngredients[ingredient.name] = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      }),

                      const SizedBox(height: 24),

                      // Instructions Section
                      const Text(
                        'Instructions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      ...recipe.instructions.asMap().entries.map((entry) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(entry.value, style: const TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                      ),

                      const SizedBox(height: 32),

                      // Nutritional Information
                      const Text(
                        'Nutritional Information',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'Calories',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text('${recipe.nutritionalInfo.calories}'),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'Protein',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text('${recipe.nutritionalInfo.protein}g'),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'Carbs',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text('${recipe.nutritionalInfo.carbs}g'),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'Fat',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text('${recipe.nutritionalInfo.fat}g'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dietary Information
                      const Text(
                        'Dietary Information',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recipe.dietaryInfo.entries
                            .where((entry) => entry.value == true)
                            .map((entry) => Chip(
                          label: Text(entry.key),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        ))
                            .toList(),
                      ),

                      const SizedBox(height: 32),

                      // Reviews Section
                      const Text(
                        'Reviews',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Add Review Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Write a Review',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Rating Stars
                            RatingBar.builder(
                              initialRating: _userRating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                setState(() {
                                  _userRating = rating;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // Review Text Field
                            TextField(
                              controller: _reviewController,
                              decoration: const InputDecoration(
                                hintText: 'Share your thoughts about this recipe...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmittingReview ? null : _submitReview,
                                child: _isSubmittingReview
                                    ? const CircularProgressIndicator()
                                    : const Text('Submit Review'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reviews List
                      StreamBuilder<List<Review>>(
                        stream: recipeService.getReviewsForRecipe(widget.recipeId),
                        builder: (context, reviewSnapshot) {
                          if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (reviewSnapshot.hasError) {
                            return Text('Error loading reviews: ${reviewSnapshot.error}');
                          }

                          final reviews = reviewSnapshot.data ?? [];

                          if (reviews.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text(
                                  'No reviews yet. Be the first to review this recipe!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: reviews.map((review) => ReviewCard(
                              review: review,
                              currentUserId: user.uid,
                              onDelete: () async {
                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                // Delete the review
                                final success = await recipeService.deleteReview(
                                  reviewId: review.id,
                                  recipeId: widget.recipeId,
                                  reviewRating: review.rating,
                                );

                                // Close loading dialog
                                Navigator.pop(context);

                                // Show result
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Review deleted successfully'
                                          : 'Failed to delete review',
                                    ),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              },
                            )).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}