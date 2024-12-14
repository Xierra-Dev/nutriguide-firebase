import 'package:flutter/material.dart';
import 'package:nutriguide/settings_page.dart';
import 'health_data_page.dart';
import 'goals_settings_page.dart';
import 'allergies_settings_page.dart';

class PreferencePage extends StatefulWidget {
  const PreferencePage({super.key});

  @override
  _PreferencePageState createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: screenHeight * 0.03,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          SlideRightRoute(page: const SettingsPage()),
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.375,
                      ),
                      child: Text(
                        'Preferences',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: screenHeight * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  children: [
                    _buildPreferenceListTile(
                      context: context,
                      leadingText: 'Health Data',
                      onTap: () {
                        Navigator.of(context).push(
                          SlideLeftRoute(page: const HealthDataPage()),
                        );
                      },
                    ),
                    _buildDivider(screenHeight),
                    _buildPreferenceListTile(
                      context: context,
                      leadingText: 'Personalized Goals',
                      onTap: () {
                        Navigator.of(context).push(
                          SlideLeftRoute(page: const GoalsSettingsPage()),
                        );
                      },
                    ),
                    _buildDivider(screenHeight),
                    _buildPreferenceListTile(
                      context: context,
                      leadingText: 'Allergies',
                      onTap: () {
                        Navigator.of(context).push(
                          SlideLeftRoute(page: const AllergiesSettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceListTile({
    required BuildContext context,
    required String leadingText,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      title: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.375,
        ),
        child: Text(
          leadingText,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenHeight * 0.02,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: screenHeight * 0.02,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(double screenHeight) {
    return Divider(
      color: Colors.white24,
      height: screenHeight * 0.001,
    );
  }
}
