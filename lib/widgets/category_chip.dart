import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Function(bool) onSelected;

  const CategoryChip({
    Key? key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Theme.of(context).chipTheme.backgroundColor,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}