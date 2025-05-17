import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

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
        title: const Text('About Recipe Cart'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.restaurant,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Recipe Cart',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version $_version (Build $_buildNumber)',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Recipe Cart is your personal recipe assistant, helping you discover, organize, and plan meals with ease.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _launchUrl('https://www.recipecart.com/privacy');
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _launchUrl('https://www.recipecart.com/terms');
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Licenses'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Recipe Cart',
                  applicationVersion: _version,
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 32),
            const Text(
              '© 2025 Recipe Cart Team',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () {
                    _launchUrl('https://www.recipecart.com');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.email),
                  onPressed: () {
                    _launchUrl('mailto:info@recipecart.com');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.facebook),
                  onPressed: () {
                    _launchUrl('https://www.facebook.com/recipecart');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.insert_comment),
                  onPressed: () {
                    _launchUrl('https://twitter.com/recipecart');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}