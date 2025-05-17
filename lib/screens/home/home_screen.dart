import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/recipe_service.dart';
import 'package:recipe_cart/widgets/recipe_card.dart';
import 'package:recipe_cart/screens/recipe/add_recipe_screen.dart';
import '../browse/browse_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipeService = Provider.of<RecipeService>(context);
    final user = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddRecipeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Hello, ${user.displayName}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'What would you like to cook today?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onTap: () {
                  // Navigate to search screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrowseScreen(initialTabIndex: 0),
                    ),
                  );
                },
                decoration: const InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(height: 24),

            // Featured Recipes
            const Text(
              'Featured Recipes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Recipe>>(
              stream: recipeService.recipes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final recipes = snapshot.data!;
                if (recipes.isEmpty) {
                  return const Center(
                    child: Text('No recipes found'),
                  );
                }

                // Show only the first 6 recipes
                final featuredRecipes = recipes.take(6).toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: featuredRecipes.length,
                  itemBuilder: (context, index) {
                    return RecipeCard(recipe: featuredRecipes[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Categories
            const Text(
              'Quick Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryCard(
                    context,
                    'Breakfast',
                    Icons.free_breakfast,
                    Colors.orange,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCategory: 'Breakfast',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Lunch',
                    Icons.lunch_dining,
                    Colors.green,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCategory: 'Lunch',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Dinner',
                    Icons.dinner_dining,
                    Colors.indigo,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCategory: 'Dinner',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Desserts',
                    Icons.cake,
                    Colors.pink,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCategory: 'Dessert',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Quick & Easy',
                    Icons.timer,
                    Colors.purple,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCategory: 'Quick & Easy',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cuisine Types
            const Text(
              'Cuisine Types',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryCard(
                    context,
                    'Italian',
                    Icons.local_pizza,
                    Colors.red,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCuisine: 'Italian',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Mexican',
                    Icons.food_bank,
                    Colors.green.shade700,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCuisine: 'Mexican',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Asian',
                    Icons.ramen_dining,
                    Colors.amber.shade800,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCuisine: 'Asian',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Mediterranean',
                    Icons.dining,
                    Colors.blue,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCuisine: 'Mediterranean',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildCategoryCard(
                    context,
                    'Indian',
                    Icons.restaurant,
                    Colors.orange.shade800,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseScreen(
                            initialCuisine: 'Indian',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add padding
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12, // Reduce font size slightly
                ),
                textAlign: TextAlign.center, // Center the text
                maxLines: 2, // Allow text to wrap to 2 lines
                overflow: TextOverflow.ellipsis, // Add ellipsis if still too long
              ),
            ),
          ],
        ),
      ),
    );
  }
}