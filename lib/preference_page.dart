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
    // Get screen size
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    // Calculate dynamic padding and sizes
    final horizontalPadding = size.width * 0.025;
    final verticalPadding = size.height * 0.02;
    final titleFontSize = isSmallScreen ? 20.0 : size.width * 0.055;
    final itemFontSize = isSmallScreen ? 16.0 : size.width * 0.045;
    final itemSpacing = size.height * 0.03;
    final iconSize = isSmallScreen ? 20.0 : size.width * 0.055;

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(size.height * 0.08),
          child: AppBar(
            backgroundColor: Colors.black,
            title: Text(
              'Preferences',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: iconSize,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  SlideRightRoute(
                    page: const SettingsPage(),
                  ),
                );
              },
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: verticalPadding * 0.5,
              left: horizontalPadding,
              right: horizontalPadding,
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
                  itemFontSize,
                  iconSize,
                ),
                SizedBox(height: itemSpacing),
                _buildPreferenceItem(
                  context,
                  'Personalized Goals',
                      () => Navigator.push(
                    context,
                    SlideLeftRoute(
                      page: const GoalsSettingsPage(),
                    ),
                  ),
                  itemFontSize,
                  iconSize,
                ),
                SizedBox(height: itemSpacing),
                _buildPreferenceItem(
                  context,
                  'Allergies',
                      () => Navigator.push(
                    context,
                    SlideLeftRoute(
                      page: const AllergiesSettingsPage(),
                    ),
                  ),
                  itemFontSize,
                  iconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(
      BuildContext context,
      String title,
      VoidCallback onTap,
      double fontSize,
      double iconSize,
      ) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: iconSize,
          ),
          onTap: onTap,
        ),
      ],
    );
  }
}