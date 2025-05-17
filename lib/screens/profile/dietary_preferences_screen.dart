import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/models/user_model.dart';
import 'package:recipe_cart/services/user_service.dart';

class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({Key? key}) : super(key: key);

  @override
  _DietaryPreferencesScreenState createState() => _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  bool _isLoading = false;
  final List<String> _allPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Paleo',
    'Low-Carb',
    'Nut-Free',
    'Seafood-Free',
  ];
  List<String> _selectedPreferences = [];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserModel>(context, listen: false);
    _selectedPreferences = List.from(user.dietaryPreferences);
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final user = Provider.of<UserModel>(context, listen: false);

      await userService.updateDietaryPreferences(
        userId: user.uid,
        preferences: _selectedPreferences,
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dietary preferences updated'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating preferences: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Preferences'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your dietary preferences:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We\'ll use these to recommend recipes tailored to your needs.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            // Preferences list
            ...List.generate(
              _allPreferences.length,
                  (index) => CheckboxListTile(
                title: Text(_allPreferences[index]),
                value: _selectedPreferences.contains(_allPreferences[index]),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedPreferences.add(_allPreferences[index]);
                    } else {
                      _selectedPreferences.remove(_allPreferences[index]);
                    }
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
                checkColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Preferences',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}