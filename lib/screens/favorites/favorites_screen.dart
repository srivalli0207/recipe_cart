import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/favorite_service.dart';
import 'package:recipe_cart/widgets/recipe_card.dart';
import 'package:recipe_cart/screens/browse/browse_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final favoriteService = Provider.of<FavoriteService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Favorites',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Favorites'),
                  content: const Text(
                    'Tap the heart icon on any recipe to add it to your favorites. '
                        'Your favorite recipes will appear here for easy access.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Recipe>>(
        future: favoriteService.getUserFavorites(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading favorites',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger rebuild
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final favoriteRecipes = snapshot.data ?? [];

          if (favoriteRecipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Favorites Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start adding recipes to your favorites!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the ♥ icon on any recipe to save it here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(initialTabIndex: 0),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Recipes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Favorite Recipes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${favoriteRecipes.length} recipe${favoriteRecipes.length != 1 ? 's' : ''} saved',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Recipes grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: favoriteRecipes.length,
                  itemBuilder: (context, index) {
                    return RecipeCard(recipe: favoriteRecipes[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}