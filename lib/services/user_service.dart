import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/database_service.dart';
import 'dart:io';

class UserService {
  final DatabaseService _db = DatabaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _userPath = 'users';

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      DatabaseEvent event = await _db.ref('$_userPath/$userId').once();
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return UserModel.fromMap(Map<String, dynamic>.from(data), userId);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      throw Exception('Failed to get user data');
    }
  }

  // Create or update user
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _db.ref('$_userPath/${user.uid}').update({
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'dietaryPreferences': user.dietaryPreferences,
        'createdAt': user.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error creating/updating user: $e');
      throw Exception('Failed to create/update user');
    }
  }

  // Update user profile information
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    List<String>? dietaryPreferences,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
      }

      if (dietaryPreferences != null) {
        updates['dietaryPreferences'] = dietaryPreferences;
      }

      await _db.ref('$_userPath/$userId').update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  // Update user profile picture
  Future<void> updateProfilePicture({
    required String userId,
    required String imagePath,
  }) async {
    try {
      // Upload image to Firebase Storage
      final File imageFile = File(imagePath);
      final storageRef = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile_picture.jpg');

      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );
      await storageRef.putFile(imageFile, metadata);

      // Get download URL
      final downloadURL = await storageRef.getDownloadURL();

      // Update user document with new profile picture URL
      await _db.ref('$_userPath/$userId').update({
        'photoUrl': downloadURL,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating profile picture: $e');
      throw Exception('Failed to update profile picture');
    }
  }

  // Get user dietary preferences
  Future<List<String>> getUserDietaryPreferences(String userId) async {
    try {
      DatabaseEvent event = await _db.ref('$_userPath/$userId').once();
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> userData = event.snapshot.value as Map;
        if (userData.containsKey('dietaryPreferences')) {
          return List<String>.from(userData['dietaryPreferences'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting dietary preferences: $e');
      throw Exception('Failed to get dietary preferences');
    }
  }

  // Update user dietary preferences
  Future<void> updateDietaryPreferences({
    required String userId,
    required List<String> preferences,
  }) async {
    try {
      await _db.ref('$_userPath/$userId').update({
        'dietaryPreferences': preferences,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating dietary preferences: $e');
      throw Exception('Failed to update dietary preferences');
    }
  }

  // Delete user account
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user storage (profile pictures, etc.)
      try {
        final storageRef = _storage.ref().child('users').child(userId);
        await storageRef.delete();
      } catch (e) {
        // Ignore if no files exist
        print('No files to delete or error deleting files: $e');
      }

      // Delete user document
      await _db.ref('$_userPath/$userId').remove();

      // Delete Firebase Auth user
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user');
    }
  }

  // Stream user data changes
  Stream<UserModel?> streamUserData(String userId) {
    return _db.ref('$_userPath/$userId').onValue.map((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return UserModel.fromMap(Map<String, dynamic>.from(data), userId);
      }
      return null;
    });
  }

  // Get user notification settings
  Future<Map<String, dynamic>> getUserNotificationSettings(String userId) async {
    try {
      DatabaseEvent event = await _db.ref('$_userPath/$userId/settings/notifications').once();
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return Map<String, dynamic>.from(data);
      }

      // Return default settings if not set
      return {
        'mealReminders': true,
        'shoppingReminders': true,
        'newRecipes': true,
        'appUpdates': true,
      };
    } catch (e) {
      print('Error getting notification settings: $e');
      throw Exception('Failed to get notification settings');
    }
  }

  // Update user notification settings
  Future<void> updateNotificationSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _db.ref('$_userPath/$userId/settings/notifications').update(settings);
    } catch (e) {
      print('Error updating notification settings: $e');
      throw Exception('Failed to update notification settings');
    }
  }
}