import 'package:firebase_database/firebase_database.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final List<String> savedRecipes;
  final List<String> dietaryPreferences;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.savedRecipes = const [],
    this.dietaryPreferences = const [],
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      savedRecipes: List<String>.from(data['savedRecipes'] ?? []),
      dietaryPreferences: List<String>.from(data['dietaryPreferences'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'savedRecipes': savedRecipes,
      'dietaryPreferences': dietaryPreferences,
      'createdAt': createdAt != null ? createdAt!.millisecondsSinceEpoch : null,
    };
  }
}