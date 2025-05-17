import 'package:flutter/material.dart';

class RecipeRatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final bool readOnly;
  final Function(double)? onRatingUpdate;

  const RecipeRatingBar({
    Key? key,
    required this.rating,
    this.size = 20,
    this.readOnly = false,
    this.onRatingUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: readOnly
              ? null
              : () {
            if (onRatingUpdate != null) {
              onRatingUpdate!(index + 1.0);
            }
          },
          child: Icon(
            index < rating.floor()
                ? Icons.star
                : (index < rating ? Icons.star_half : Icons.star_border),
            color: Theme.of(context).colorScheme.secondary,
            size: size,
          ),
        );
      }),
    );
  }
}