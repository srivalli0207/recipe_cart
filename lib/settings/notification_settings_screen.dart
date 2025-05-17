import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _allowNotifications = true;
  bool _mealReminders = true;
  bool _shoppingReminders = true;
  bool _weeklyRecipeSuggestions = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allowNotifications = prefs.getBool('allowNotifications') ?? true;
      _mealReminders = prefs.getBool('mealReminders') ?? true;
      _shoppingReminders = prefs.getBool('shoppingReminders') ?? true;
      _weeklyRecipeSuggestions = prefs.getBool('weeklyRecipeSuggestions') ?? true;

      final hour = prefs.getInt('reminderTimeHour') ?? 18;
      final minute = prefs.getInt('reminderTimeMinute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allowNotifications', _allowNotifications);
    await prefs.setBool('mealReminders', _mealReminders);
    await prefs.setBool('shoppingReminders', _shoppingReminders);
    await prefs.setBool('weeklyRecipeSuggestions', _weeklyRecipeSuggestions);
    await prefs.setInt('reminderTimeHour', _reminderTime.hour);
    await prefs.setInt('reminderTimeMinute', _reminderTime.minute);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Allow Notifications'),
            subtitle: const Text('Enable or disable all notifications'),
            value: _allowNotifications,
            onChanged: (bool value) {
              setState(() {
                _allowNotifications = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          if (_allowNotifications) ...[
            SwitchListTile(
              title: const Text('Meal Plan Reminders'),
              subtitle: const Text('Get reminders for planned meals'),
              value: _mealReminders,
              onChanged: (bool value) {
                setState(() {
                  _mealReminders = value;
                });
                _saveSettings();
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Shopping List Reminders'),
              subtitle: const Text('Get reminders for items in your shopping list'),
              value: _shoppingReminders,
              onChanged: (bool value) {
                setState(() {
                  _shoppingReminders = value;
                });
                _saveSettings();
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Weekly Recipe Suggestions'),
              subtitle: const Text('Receive weekly recipe suggestions'),
              value: _weeklyRecipeSuggestions,
              onChanged: (bool value) {
                setState(() {
                  _weeklyRecipeSuggestions = value;
                });
                _saveSettings();
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text('Notifications will be sent at ${_reminderTime.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(context),
            ),
          ],
        ],
      ),
    );
  }
}