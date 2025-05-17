import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  // Create user object based on FirebaseUser
  UserModel? _userFromFirebaseUser(User? user) {
    if (user == null) return null;

    return UserModel(
      uid: user.uid,
      displayName: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  // Auth change user stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Sign in with email & password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Register with email & password
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      print('Step 1: Attempting to create Firebase Auth account');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Step 2: Auth account created successfully');

      User? user = result.user;
      print('Step 3: Updating display name');

      await user?.updateDisplayName(displayName);
      print('Step 4: Display name updated successfully');

      // Create a new document for the user with the uid
      print('Step 5: Creating user entry in Realtime Database');
      await _db.ref('users/${user?.uid}').set({
        'displayName': displayName,
        'email': email,
        'photoUrl': null,
        'savedRecipes': [],
        'createdAt': ServerValue.timestamp,
      });
      print('Step 6: User data saved to database successfully');

      return _userFromFirebaseUser(user);
    } catch (e) {
      print('Error in registration process: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      return;
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DatabaseEvent userEvent = await _db.ref('users/${user.uid}').once();
        if (userEvent.snapshot.exists) {
          Map<dynamic, dynamic> userData = userEvent.snapshot.value as Map;
          return UserModel.fromMap(Map<String, dynamic>.from(userData), user.uid);
        }
      }
      return _userFromFirebaseUser(user);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }

        // Update Firebase document
        Map<String, dynamic> data = {};
        if (displayName != null) data['displayName'] = displayName;
        if (photoUrl != null) data['photoUrl'] = photoUrl;

        await _db.ref('users/${user.uid}').update(data);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }
}