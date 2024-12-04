import 'package:flutter/material.dart';
import 'health_data_page.dart';
import 'goals_settings_page.dart';
import 'allergies_settings_page.dart';

class PreferencePage extends StatelessWidget {
  const PreferencePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPreferenceItem(
              context,
              'Health Data',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HealthDataPage(),
                ),
              ),
            ),
            _buildPreferenceItem(
              context,
              'Personalized Goals',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalsSettingsPage(),
                ),
              ),
            ),
            _buildPreferenceItem(
              context,
              'Allergies',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllergiesSettingsPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(
      BuildContext context, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.white,
          ),
          onTap: onTap,
        ),
        const Divider(
          color: Colors.grey,
          height: 1,
        ),
      ],
    );
  }
} 