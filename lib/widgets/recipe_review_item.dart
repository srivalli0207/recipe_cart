import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recipe_cart/models/review_model.dart';
import 'package:recipe_cart/widgets/recipe_rating_bar.dart';

class RecipeReviewItem extends StatelessWidget {
  final Review review;

  const RecipeReviewItem({
    Key? key,
    required this.review,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and rating row
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty
                      ? NetworkImage(review.userPhotoUrl!)
                      : null,
                  child: review.userPhotoUrl == null || review.userPhotoUrl!.isEmpty
                      ? Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                // User name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().format(review.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating
                RecipeRatingBar(
                  rating: review.rating,
                  size: 18,
                  readOnly: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review content
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),

            // Review images (if any)
            if (review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.userPhotoUrl!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: GestureDetector(
                          onTap: () {
                            // Show full-screen image
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  fit: StackFit.passthrough,
                                  children: [
                                    InteractiveViewer(
                                      boundaryMargin: const EdgeInsets.all(20),
                                      minScale: 0.5,
                                      maxScale: 3.0,
                                      child: Image.network(
                                        review.userPhotoUrl![index],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Image.network(
                            review.userPhotoUrl![index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}