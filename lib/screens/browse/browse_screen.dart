// lib/screens/browse/browse_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/services/recipe_service.dart';
import 'package:recipe_cart/widgets/recipe_card.dart';
import 'package:recipe_cart/widgets/category_chip.dart';

class BrowseScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialCategory;
  final String? initialCuisine;

  const BrowseScreen({
    Key? key,
    this.initialTabIndex = 1,
    this.initialCategory,
    this.initialCuisine,
  }) : super(key: key);

  @override
  _BrowseScreenState createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  List<Recipe> _searchResults = [];
  bool _isSearching = false;

  // Selected filters
  String? _selectedCategory;
  String? _selectedCuisine;
  String? _selectedDiet;

  // Filter options
  final List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snack',
    'Appetizer',
    'Salad',
    'Soup',
    'Quick & Easy'
  ];

  final List<String> _cuisines = [
    'Italian',
    'Mexican',
    'Asian',
    'Mediterranean',
    'Indian',
    'American',
    'French',
    'Middle Eastern',
    'Thai'
  ];

  final List<String> _diets = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Low-Carb',
    'Keto',
    'Paleo'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);

    // Apply initial filters if provided
    _selectedCategory = widget.initialCategory;
    _selectedCuisine = widget.initialCuisine;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Perform search
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final recipeService = Provider.of<RecipeService>(context, listen: false);
    final results = await recipeService.searchRecipes(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Recipes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search'),
            Tab(text: 'Categories'),
            Tab(text: 'Cuisines'),
            Tab(text: 'Dietary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Search Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _performSearch(value);
                  },
                ),
              ),
              Expanded(
                child: _searchQuery.isEmpty
                    ? const Center(
                  child: Text('Search for recipes by name, ingredient, etc.'),
                )
                    : _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                    ? const Center(
                  child: Text('No recipes found'),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return RecipeCard(recipe: _searchResults[index]);
                  },
                ),
              ),
            ],
          ),

          // Categories Tab
          _buildFilterTab(
            filterTitle: 'Recipe Categories',
            filterItems: _categories,
            selectedFilter: _selectedCategory,
            filterIcon: Icons.category,
            onFilterSelected: (category) {
              setState(() {
                _selectedCategory = category == _selectedCategory ? null : category;
                _selectedCuisine = null;
                _selectedDiet = null;
              });
            },
          ),

          // Cuisines Tab
          _buildFilterTab(
            filterTitle: 'Cuisine Types',
            filterItems: _cuisines,
            selectedFilter: _selectedCuisine,
            filterIcon: Icons.restaurant,
            onFilterSelected: (cuisine) {
              setState(() {
                _selectedCuisine = cuisine == _selectedCuisine ? null : cuisine;
                _selectedCategory = null;
                _selectedDiet = null;
              });
            },
          ),

          // Dietary Tab
          _buildFilterTab(
            filterTitle: 'Dietary Preferences',
            filterItems: _diets,
            selectedFilter: _selectedDiet,
            filterIcon: Icons.restaurant_menu,
            onFilterSelected: (diet) {
              setState(() {
                _selectedDiet = diet == _selectedDiet ? null : diet;
                _selectedCategory = null;
                _selectedCuisine = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String filterTitle,
    required List<String> filterItems,
    required String? selectedFilter,
    required IconData filterIcon,
    required Function(String) onFilterSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filterTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filterItems.map((item) {
                  return CategoryChip(
                    label: item,
                    icon: filterIcon,
                    isSelected: item == selectedFilter,
                    onSelected: (selected) => onFilterSelected(item),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<RecipeService>(
            builder: (context, recipeService, child) {
              // Get the appropriate stream based on the filter
              Stream<List<Recipe>> recipeStream;

              if (selectedFilter != null) {
                if (filterTitle == 'Recipe Categories') {
                  recipeStream = recipeService.getRecipesByCategory(selectedFilter!);
                } else if (filterTitle == 'Cuisine Types') {
                  recipeStream = recipeService.getRecipesByCuisine(selectedFilter!);
                } else if (filterTitle == 'Dietary Preferences') {
                  recipeStream = recipeService.getRecipesByDietaryPreference(selectedFilter!);
                } else {
                  recipeStream = recipeService.recipes;
                }
              } else {
                recipeStream = recipeService.recipes;
              }

              return StreamBuilder<List<Recipe>>(
                stream: recipeStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Something went wrong'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final recipes = snapshot.data ?? [];
                  if (recipes.isEmpty) {
                    return const Center(
                      child: Text('No recipes found'),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      return RecipeCard(recipe: recipes[index]);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}