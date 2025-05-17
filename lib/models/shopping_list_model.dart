class ShoppingListItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String? recipeId;
  final String? recipeName;
  bool isChecked;

  ShoppingListItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.recipeId,
    this.recipeName,
    this.isChecked = false,
  });

  factory ShoppingListItem.fromMap(Map<String, dynamic> data, String id) {
    return ShoppingListItem(
      id: id,
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
      recipeId: data['recipeId'],
      recipeName: data['recipeName'],
      isChecked: data['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'isChecked': isChecked,
    };
  }

  ShoppingListItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? recipeId,
    String? recipeName,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
