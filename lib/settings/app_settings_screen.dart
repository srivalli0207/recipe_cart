// lib/screens/settings/app_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:recipe_cart/services/theme_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _useCelsius = true;
  bool _showCalories = true;
  bool _saveRecipesOffline = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useCelsius = prefs.getBool('useCelsius') ?? true;
      _showCalories = prefs.getBool('showCalories') ?? true;
      _saveRecipesOffline = prefs.getBool('saveRecipesOffline') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCelsius', _useCelsius);
    await prefs.setBool('showCalories', _showCalories);
    await prefs.setBool('saveRecipesOffline', _saveRecipesOffline);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme throughout the app'),
            value: themeService.isDarkMode,
            onChanged: (bool value) {
              themeService.toggleTheme();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Temperature Unit'),
            subtitle: Text('Use ${_useCelsius ? 'Celsius' : 'Fahrenheit'} for recipes'),
            value: _useCelsius,
            onChanged: (bool value) {
              setState(() {
                _useCelsius = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Show Calories'),
            subtitle: const Text('Display calorie information on recipes'),
            value: _showCalories,
            onChanged: (bool value) {
              setState(() {
                _showCalories = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Save Recipes Offline'),
            subtitle: const Text('Download recipes for offline use'),
            value: _saveRecipesOffline,
            onChanged: (bool value) {
              setState(() {
                _saveRecipesOffline = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear App Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.cleaning_services),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cache'),
                  content: const Text('This will remove all temporary files. Your saved recipes and preferences will not be affected.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Implement cache clearing logic here
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache cleared'),
                          ),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}