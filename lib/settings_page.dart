import 'package:flutter/material.dart';
import 'package:nutriguide/about_nutriGuide_page.dart';
import 'package:nutriguide/notifications_page.dart';
import 'account_page.dart';
import '/profile_page.dart';
import 'services/auth_service.dart';
import 'profile_edit_page.dart';
import 'preference_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

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

class _SettingsPageState extends State<SettingsPage> {
  String? email;
  String? displayName;
  String? firstName;
  String? lastName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authService = AuthService();

    try {
      email = authService.getCurrentUserEmail();

      // Retrieve user names
      Map<String, String?> userNames = await authService.getUserNames();
      displayName = userNames['displayName'];
      firstName = userNames['firstName'];
      lastName = userNames['lastName'];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size and orientation
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final orientation = mediaQuery.orientation;

    // Responsive font sizes
    final double titleFontSize = screenWidth * 0.055; // Approximately 24 on most devices
    final double listTileFontSize = screenWidth * 0.0435; // Approximately 18 on most devices

    // Responsive padding and spacing
    final double horizontalPadding = screenWidth * 0.04; // 15 on most devices
    final double spaceBetweenItems = screenHeight * 0.03; // 32 on most devices

    // Responsive icon sizes
    final double backIconSize = screenWidth * 0.065; // 30 on most devices
    final double trailingIconSize = screenWidth * 0.056; // 24 on most devices

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - (2 * horizontalPadding),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white, size: backIconSize),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            SlideRightRoute(page: const ProfilePage()),
                          );
                        },
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spaceBetweenItems),
                  _buildResponsiveSettingsListTile(
                    context: context,
                    leadingText: 'Account',
                    trailingText: email ?? 'Loading...',
                    fontSize: listTileFontSize,
                    trailingIconSize: trailingIconSize,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        SlideLeftRoute(page: const AccountPage()),
                      );
                    },
                  ),
                  SizedBox(height: spaceBetweenItems * 0.8),
                  _buildResponsiveSettingsListTile(
                    context: context,
                    leadingText: 'Profile',
                    trailingText: displayName ?? 'Loading...',
                    fontSize: listTileFontSize,
                    trailingIconSize: trailingIconSize,
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideLeftRoute(page: const ProfileEditPage()),
                      );
                    },
                  ),
                  SizedBox(height: spaceBetweenItems * 0.8),
                  // Added the missing method
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Notifications',
                    trailingText: '',
                    fontSize: listTileFontSize,
                    trailingIconSize: trailingIconSize,
                    onTap: () {
                      Navigator.of(context).push(
                        SlideLeftRoute(page: const NotificationsPage()),
                      );
                    },
                  ),
                  SizedBox(height: spaceBetweenItems * 0.8),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Preferences',
                    trailingText: '',
                    fontSize: listTileFontSize,
                    trailingIconSize: trailingIconSize,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        SlideLeftRoute(
                          page: const PreferencePage(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: spaceBetweenItems * 0.8),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'About NutriGuide',
                    trailingText: '',
                    fontSize: listTileFontSize,
                    trailingIconSize: trailingIconSize,
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideLeftRoute(
                          page: const AboutNutriguidePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create responsive list tiles with dynamic text overflow
  Widget _buildResponsiveSettingsListTile({
    required BuildContext context,
    required String leadingText,
    required String trailingText,
    required double fontSize,
    required double trailingIconSize,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width for trailing text
        // Subtracting space for leading text, icon, and some padding
        final availableWidth = constraints.maxWidth * 0.5;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 7.5),
          leading: Text(
            leadingText,
            style: TextStyle(color: Colors.white, fontSize: fontSize),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: availableWidth),
                  child: Text(
                    trailingText,
                    style: TextStyle(color: Colors.white, fontSize: fontSize),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              if (trailingText.isNotEmpty)
                SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: trailingIconSize),
            ],
          ),
          onTap: onTap,
        );
      },
    );
  }

  // Added the missing method without dynamic width calculation
  Widget _buildSettingsListTile({
    required BuildContext context,
    required String leadingText,
    required String trailingText,
    required double fontSize,
    required double trailingIconSize,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 7.5),
      leading: Text(
        leadingText,
        style: TextStyle(color: Colors.white, fontSize: fontSize),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty)
            Text(
              trailingText,
              style: TextStyle(color: Colors.white, fontSize: fontSize),
            ),
          if (trailingText.isNotEmpty)
            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
          Icon(Icons.arrow_forward_ios, color: Colors.white, size: trailingIconSize),
        ],
      ),
      onTap: onTap,
    );
  }
}