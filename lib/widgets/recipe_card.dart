import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/favorite_service.dart';
import 'package:recipe_cart/screens/recipe_detail_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;

  const RecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = Provider.of<UserModel>(context, listen: false);
    final favoriteService = Provider.of<FavoriteService>(context, listen: false);

    try {
      bool isFavorite = await favoriteService.isFavorite(user.uid, widget.recipe.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<UserModel>(context, listen: false);
    final favoriteService = Provider.of<FavoriteService>(context, listen: false);

    try {
      if (_isFavorite) {
        await favoriteService.removeFavorite(user.uid, widget.recipe.id);
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.recipe.name} removed from favorites'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await favoriteService.addFavorite(user.uid, widget.recipe.id);
        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.recipe.name} added to favorites'),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipeId: widget.recipe.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recipe Image with Favorite Button
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: widget.recipe.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                // Favorite button overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                        : IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: _toggleFavorite,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Name
                  Text(
                    widget.recipe.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Rating and Reviews
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.recipe.rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 16.0,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.recipe.reviewCount > 0
                              ? '${widget.recipe.rating.toStringAsFixed(1)} (${widget.recipe.reviewCount})'
                              : 'No reviews',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.recipe.reviewCount > 0
                                ? Colors.grey[700]
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Cuisine Type & Cook Time
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.restaurant, size: 12),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                widget.recipe.cuisineType,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.recipe.cookTimeMinutes} min',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}