import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/recipe_model.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/recipe_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({Key? key}) : super(key: key);

  @override
  _AddRecipeScreenState createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  List<String> _cuisineTypes = [
    'Italian',
    'Mexican',
    'Asian',
    'American',
    'Mediterranean',
    'Indian',
    'French',
    'Other'
  ];
  String _selectedCuisineType = 'Italian';
  List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Appetizer',
    'Dessert',
    'Snack',
    'Drink',
    'Side Dish'
  ];
  List<String> _selectedCategories = [];

  Map<String, bool> _dietaryInfo = {
    'Vegetarian': false,
    'Vegan': false,
    'Gluten-Free': false,
    'Dairy-Free': false,
    'Keto': false,
    'Paleo': false,
    'Low-Carb': false,
    'Nut-Free': false,
  };

  List<Map<String, dynamic>> _ingredientsData = [
    {'name': '', 'quantity': '', 'unit': 'g'}
  ];

  List<String> _instructionsData = [''];

  final List<String> _units = [
    'g',
    'kg',
    'ml',
    'l',
    'tsp',
    'tbsp',
    'cup',
    'pcs',
    'oz',
    'lb',
    'pinch'
  ];

  // Nutritional info
  final _caloriesController = TextEditingController(text: '0');
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  final _sugarController = TextEditingController(text: '0');
  final _fiberController = TextEditingController(text: '0');

  File? _recipeImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cookTimeController.dispose();
    _prepTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _recipeImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredientsData.add({'name': '', 'quantity': '', 'unit': 'g'});
    });
  }

  void _removeIngredient(int index) {
    if (_ingredientsData.length > 1) {
      setState(() {
        _ingredientsData.removeAt(index);
      });
    }
  }

  void _addInstruction() {
    setState(() {
      _instructionsData.add('');
    });
  }

  void _removeInstruction(int index) {
    if (_instructionsData.length > 1) {
      setState(() {
        _instructionsData.removeAt(index);
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<UserModel>(context, listen: false);
      final recipeService = Provider.of<RecipeService>(context, listen: false);

      // Prepare ingredients list - filter out empty ingredients
      final List<Ingredient> ingredients = _ingredientsData
          .where((data) => data['name'].toString().trim().isNotEmpty)
          .map((data) => Ingredient(
        name: data['name'].toString().trim(),
        quantity: double.tryParse(data['quantity'].toString()) ?? 0,
        unit: data['unit'].toString(),
      ))
          .toList();

      // Prepare nutritional info
      final nutritionalInfo = NutritionalInfo(
        calories: int.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        sugar: double.tryParse(_sugarController.text) ?? 0,
        fiber: double.tryParse(_fiberController.text) ?? 0,
      );

      // Call the addRecipe method - REMOVED the ! operator
      final savedRecipe = await recipeService.addRecipe(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        authorId: user.uid,
        authorName: user.displayName ?? 'Anonymous',
        imageFile: _recipeImage, // NO MORE ! - this can be null now
        ingredients: ingredients,
        instructions: _instructionsData.where((step) => step.trim().isNotEmpty).toList(),
        prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
        cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 0,
        servings: int.tryParse(_servingsController.text) ?? 1,
        categories: _selectedCategories,
        cuisineType: _selectedCuisineType,
        dietaryInfo: _dietaryInfo,
        nutritionalInfo: nutritionalInfo,
      );

      setState(() {
        _isLoading = false;
      });

      if (savedRecipe != null) {
        // Show success message with different text based on image
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _recipeImage != null
                    ? 'Recipe saved successfully with image'
                    : 'Recipe saved successfully with default image'
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to recipe list/detail
        Navigator.pop(context, savedRecipe);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save recipe. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving recipe: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recipe'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecipe,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Recipe image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    image: _recipeImage != null
                        ? DecorationImage(
                      image: FileImage(_recipeImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _recipeImage == null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add recipe photo',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Recipe name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recipe description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recipe details - cook time, prep time, servings
              Row(
                children: [
                  // Prep time
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Prep Time (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Cook time
                  Expanded(
                    child: TextFormField(
                      controller: _cookTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Cook Time (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Servings
                  Expanded(
                    child: TextFormField(
                      controller: _servingsController,
                      decoration: const InputDecoration(
                        labelText: 'Servings',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cuisine type
              DropdownButtonFormField<String>(
                value: _selectedCuisineType,
                decoration: const InputDecoration(
                  labelText: 'Cuisine Type',
                  border: OutlineInputBorder(),
                ),
                items: _cuisineTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCuisineType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Recipe categories
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dietary info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dietary Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietaryInfo.keys.map((diet) {
                      final isSelected = _dietaryInfo[diet] ?? false;
                      return FilterChip(
                        label: Text(diet),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _dietaryInfo[diet] = selected;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ingredients section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fixed Ingredients list - Two-row layout to prevent overflow
              for (int i = 0; i < _ingredientsData.length; i++) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Ingredient name - takes up full width
                            Expanded(
                              child: TextFormField(
                                initialValue: _ingredientsData[i]['name'],
                                decoration: const InputDecoration(
                                  labelText: 'Ingredient',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _ingredientsData[i]['name'] = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Remove button
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _removeIngredient(i),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Second row for quantity and unit
                        Row(
                          children: [
                            // Quantity
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: _ingredientsData[i]['quantity'],
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _ingredientsData[i]['quantity'] = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Unit
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: _ingredientsData[i]['unit'],
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(),
                                ),
                                items: _units.map((unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _ingredientsData[i]['unit'] = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Instructions section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addInstruction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Instructions list
              for (int i = 0; i < _instructionsData.length; i++) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step number
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Step ${i + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _removeInstruction(i),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Step description
                        TextFormField(
                          initialValue: _instructionsData[i],
                          decoration: const InputDecoration(
                            labelText: 'Instructions',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter step instructions';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _instructionsData[i] = value;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Nutritional Information
              const SizedBox(height: 24),
              const Text(
                'Nutritional Information (per serving)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sugarController,
                      decoration: const InputDecoration(
                        labelText: 'Sugar (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fiberController,
                      decoration: const InputDecoration(
                        labelText: 'Fiber (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _saveRecipe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Recipe',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}