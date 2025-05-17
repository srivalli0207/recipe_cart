import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/auth_service.dart';
import 'package:recipe_cart/services/user_service.dart';
import 'package:recipe_cart/widgets/profile_menu_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        final userService = Provider.of<UserService>(context, listen: false);
        final user = Provider.of<UserModel>(context, listen: false);

        await userService.updateProfilePicture(
          userId: user.uid,
          imagePath: image.path,
        );

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile picture: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final authService = Provider.of<AuthService>(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit profile',
            onPressed: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey,
                  )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // User name
            Text(
              user.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // User email
            Text(
              firebaseUser?.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Profile menu
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Edit profile
            ProfileMenuItem(
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {
                Navigator.pushNamed(context, '/edit_profile');
              },
            ),

            // Dietary preferences
            ProfileMenuItem(
              icon: Icons.food_bank,
              title: 'Dietary Preferences',
              onTap: () {
                Navigator.pushNamed(context, '/dietary_preferences');
              },
            ),

            // Settings section
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // App settings
            ProfileMenuItem(
              icon: Icons.settings,
              title: 'App Settings',
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),

            // Notification settings
            ProfileMenuItem(
              icon: Icons.notifications,
              title: 'Notification Settings',
              onTap: () {
                Navigator.pushNamed(context, '/notification_settings');
              },
            ),

            // Help & Support section
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Help center
            ProfileMenuItem(
              icon: Icons.help,
              title: 'Help Center',
              onTap: () {
                Navigator.pushNamed(context, '/help_center');
              },
            ),

            // About
            ProfileMenuItem(
              icon: Icons.info,
              title: 'About Recipe Cart',
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),

            // Logout section
            const SizedBox(height: 32),

            // Logout button
            ElevatedButton.icon(
              onPressed: () async {
                // Show confirmation dialog
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text(
                        'Are you sure you want to log out of Recipe Cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await authService.signOut();
                  // Navigate to login screen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}