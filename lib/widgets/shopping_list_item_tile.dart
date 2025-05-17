import 'package:flutter/material.dart';
import 'package:recipe_cart/models/shopping_list_model.dart';

class ShoppingListItemTile extends StatelessWidget {
  final ShoppingListItem item;
  final Function(bool) onCheckedChanged;
  final VoidCallback onDelete;

  const ShoppingListItemTile({
    Key? key,
    required this.item,
    required this.onCheckedChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (bool? value) {
            if (value != null) {
              onCheckedChanged(value);
            }
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            fontSize: 16,
          ),
        ),
        subtitle: item.recipeName != null
            ? Text(
          'From: ${item.recipeName}',
          style: const TextStyle(
            fontSize: 12,
          ),
        )
            : null,
        trailing: Text(
          '${item.quantity} ${item.unit}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}