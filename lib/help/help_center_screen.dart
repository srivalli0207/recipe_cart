import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const ExpansionTile(
            title: Text('Frequently Asked Questions'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How do I create a meal plan?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Go to the Meal Plan tab and tap on the day you want to add a meal to. Then select a recipe and meal type.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'How do I add items to my shopping list?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You can add individual items manually or generate a shopping list from your meal plan.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Can I save recipes for later?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Yes, tap the bookmark icon on any recipe to save it to your favorites.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          ListTile(
            title: const Text('Contact Support'),
            subtitle: const Text('Have a question or issue? Contact our team.'),
            trailing: const Icon(Icons.email),
            onTap: () {
              _launchUrl('mailto:support@recipecart.com');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Video Tutorials'),
            subtitle: const Text('Watch tutorials on how to use Recipe Cart'),
            trailing: const Icon(Icons.video_library),
            onTap: () {
              // Navigate to video tutorials screen or launch YouTube channel
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('User Guide'),
            subtitle: const Text('Detailed instructions for using the app'),
            trailing: const Icon(Icons.menu_book),
            onTap: () {
              // Navigate to user guide screen or launch web guide
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Report a Bug'),
            subtitle: const Text('Found something not working right?'),
            trailing: const Icon(Icons.bug_report),
            onTap: () {
              _launchUrl('mailto:bugs@recipecart.com?subject=Bug%20Report');
            },
          ),
        ],
      ),
    );
  }
}