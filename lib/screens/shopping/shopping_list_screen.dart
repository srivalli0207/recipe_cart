import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/models/shopping_list_model.dart';
import 'package:recipe_cart/services/shopping_list_service.dart';
import 'package:recipe_cart/widgets/shopping_list_item_tile.dart';
import 'package:uuid/uuid.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();
  final Uuid _uuid = Uuid();

  // Unit dropdown
  String _selectedUnit = 'pcs';
  final List<String> _units = [
    'pcs',
    'g',
    'kg',
    'ml',
    'l',
    'tsp',
    'tbsp',
    'cup',
    'oz',
    'lb',
    'pinch',
    'bunch',
    'cloves',
    'slices',
  ];

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty || _quantityController.text.trim().isEmpty) {
      return;
    }

    final shoppingListService = Provider.of<ShoppingListService>(context, listen: false);
    final user = Provider.of<UserModel>(context, listen: false);

    await shoppingListService.addShoppingListItem(
      userId: user.uid,
      name: _itemController.text.trim(),
      quantity: double.tryParse(_quantityController.text) ?? 1.0,
      unit: _selectedUnit,
    );

    // Clear the input fields
    _itemController.clear();
    _quantityController.clear();
    setState(() {
      _selectedUnit = 'pcs'; // Reset to default unit
    });
  }

  @override
  Widget build(BuildContext context) {
    final shoppingListService = Provider.of<ShoppingListService>(context);
    final user = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear_checked') {
                await shoppingListService.clearCheckedItems(user.uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checked items cleared')),
                );
              } else if (value == 'clear_all') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Items'),
                    content: const Text('Are you sure you want to clear all items from your shopping list?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await shoppingListService.clearShoppingList(user.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Shopping list cleared')),
                          );
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_checked',
                child: Text('Clear Checked Items'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All Items'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Add item section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // First row - Item name
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        decoration: const InputDecoration(
                          labelText: 'Item',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Second row - Quantity, Unit dropdown, and Add button
                Row(
                  children: [
                    // Quantity field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unit dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: _units.map((String unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedUnit = newValue;
                            });
                          }
                        },
                        isExpanded: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add button
                    Container(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(Icons.add, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Shopping list items
          Expanded(
            child: StreamBuilder<List<ShoppingListItem>>(
              stream: shoppingListService.getShoppingList(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your shopping list is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add items manually or from recipes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ShoppingListItemTile(
                      item: item,
                      onCheckedChanged: (checked) {
                        shoppingListService.toggleItemChecked(
                          userId: user.uid,
                          itemId: item.id,
                          isChecked: checked,
                        );
                      },
                      onDelete: () {
                        shoppingListService.removeShoppingListItem(
                          userId: user.uid,
                          itemId: item.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}