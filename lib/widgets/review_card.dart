import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:recipe_cart/models/review_model.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final String? currentUserId;  // Pass current user ID from parent
  final Function()? onDelete;

  const ReviewCard({
    Key? key,
    required this.review,
    this.currentUserId,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    final isCurrentUser = currentUserId == review.userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info, rating, and delete button
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: review.userPhotoUrl != null && review.userPhotoUrl!.isNotEmpty
                      ? NetworkImage(review.userPhotoUrl!)
                      : null,
                  child: review.userPhotoUrl == null || review.userPhotoUrl!.isEmpty
                      ? Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
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
                        formatter.format(review.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating
                RatingBar.builder(
                  initialRating: review.rating,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 18,
                  ignoreGestures: true,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {},
                ),
                const SizedBox(width: 8),
                // Delete button (only for current user)
                if (isCurrentUser && onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _showDeleteConfirmation(context),
                    tooltip: 'Delete review',
                  ),
              ],
            ),
            // Review content
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: const Text(
            'Are you sure you want to delete this review? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onDelete != null) {
                  onDelete!();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}