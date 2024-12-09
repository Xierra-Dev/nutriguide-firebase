import 'package:flutter/material.dart';
import 'package:nutriguide/settings_page.dart';
import 'health_data_page.dart';
import 'goals_settings_page.dart';
import 'allergies_settings_page.dart';

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        ) =>
    page,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
}

class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;

  SlideLeftRoute({required this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        ) =>
    page,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
}

class PreferencePage extends StatelessWidget {
  const PreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                SlideRightRoute(
                  page:  const SettingsPage(),
                ),
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 32,
          ),
          child: Column(
            children: [
              _buildPreferenceItem(
                context,
                'Health Data',
                () => Navigator.push(
                  context,
                  SlideLeftRoute(
                    page: const HealthDataPage(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildPreferenceItem(
                context,
                'Personalized Goals',
                () => Navigator.push(
                  context,
                  SlideLeftRoute(
                    page:  const GoalsSettingsPage(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildPreferenceItem(
                context,
                'Allergies',
                () => Navigator.push(
                  context,
                  SlideLeftRoute(
                    page:  const AllergiesSettingsPage(),
                  ),
                ),
              ),
            ],
          ),
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
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.white,
          ),
          onTap: onTap,
        ),
      ],
    );
  }
} 