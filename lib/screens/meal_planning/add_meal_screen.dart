import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/meal_plan_service.dart';
import 'package:recipe_cart/services/recipe_service.dart';
import 'package:intl/intl.dart';

class AddMealScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddMealScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _AddMealScreenState createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedMealType = 'Breakfast';
  Recipe? _selectedRecipe;
  int _servings = 1;
  bool _isLoading = false;
  List<Recipe> _recipes = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // List of meal types
  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      // Use recipes stream instead of non-existent getUserRecipes method
      final recipesSnapshot = await recipeService.recipes.first;

      setState(() {
        _recipes = recipesSnapshot;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading recipes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Recipe> get _filteredRecipes {
    if (_searchQuery.isEmpty) {
      return _recipes;
    }

    return _recipes.where((recipe) {
      return recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _addMealToPlan() async {
    if (!_formKey.currentState!.validate() || _selectedRecipe == null) {
      // Show error if no recipe is selected
      if (_selectedRecipe == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a recipe'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<UserModel>(context, listen: false);
      final mealPlanService = Provider.of<MealPlanService>(context, listen: false);

      // Get meal plan for date
      final mealPlan = await mealPlanService.getMealPlanForDate(
        user.uid,
        widget.selectedDate,
      );

      if (mealPlan == null) {
        throw Exception('Failed to get meal plan');
      }

      // Add meal to meal plan
      await mealPlanService.addMealToMealPlan(
        userId: user.uid,
        mealPlanId: mealPlan.id,
        recipeId: _selectedRecipe!.id,
        mealType: _selectedMealType.toLowerCase(),
      );

      setState(() {
        _isLoading = false;
      });

      // Return true to indicate a meal was added
      Navigator.pop(context, true);
    } catch (e) {
      print('Error adding meal to plan: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding meal to plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Meal for ${DateFormat('MMM d').format(widget.selectedDate)}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meal type selection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedMealType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    items: _mealTypes.map((mealType) {
                      return DropdownMenuItem<String>(
                        value: mealType,
                        child: Text(mealType),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMealType = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a meal type';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // Servings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Servings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _servings > 1
                            ? () {
                          setState(() {
                            _servings--;
                          });
                        }
                            : null,
                      ),
                      Text(
                        '$_servings',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _servings++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Recipe search
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recipe',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search recipes...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Recipe list
            Expanded(
              child: _recipes.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No recipes found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add recipes to your collection first',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/add_recipe');
                      },
                      child: const Text('Add Recipe'),
                    ),
                  ],
                ),
              )
                  : _filteredRecipes.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No matching recipes found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try a different search term',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _filteredRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = _filteredRecipes[index];
                  final isSelected = _selectedRecipe?.id == recipe.id;

                  return ListTile(
                    leading: recipe.imageUrl.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        recipe.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.grey,
                      ),
                    ),
                    title: Text(recipe.name),
                    subtitle: Text(
                      recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected
                        ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedRecipe = recipe;
                      });
                    },
                    selected: isSelected,
                    tileColor: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _addMealToPlan,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text(
            'Add to Meal Plan',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}