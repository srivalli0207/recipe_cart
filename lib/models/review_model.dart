import 'package:firebase_database/firebase_database.dart';

class Review {
  final String id;
  final String recipeId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory Review.fromMap(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      recipeId: data['recipeId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      date: data['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['date'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'date': date.millisecondsSinceEpoch,
    };
  }
}