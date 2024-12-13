import 'package:flutter/material.dart';
import 'package:nutriguide/about_nutriGuide_page.dart';
import 'package:nutriguide/notifications_page.dart';
import 'account_page.dart';
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
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
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
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
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
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.375,
                    ),
                    child: Text(
                      'Settings',
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
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Account',
                    trailingText: email ?? '',
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        SlideLeftRoute(page: const AccountPage()),
                      );
                    },
                  ),
                  _buildDivider(screenHeight),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Profile',
                    trailingText: displayName ?? '',
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideLeftRoute(page: const ProfileEditPage()),
                      );
                    },
                  ),
                  _buildDivider(screenHeight),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Notifications',
                    trailingText: '',
                    onTap: () {
                      Navigator.of(context).push(
                        SlideLeftRoute(page: const NotificationsPage()),
                      );
                    },
                  ),
                  _buildDivider(screenHeight),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Preferences',
                    trailingText: '',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        SlideLeftRoute(page: const PreferencePage()),
                      );
                    },
                  ),
                  _buildDivider(screenHeight),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'About NutriGuide',
                    trailingText: '',
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideLeftRoute(page: const AboutNutriguidePage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsListTile({
    required BuildContext context,
    required String leadingText,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

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
            fontSize: screenHeight * 0.02 * textScaleFactor,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty)
            Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.375,
              ),
              margin: EdgeInsets.only(right: screenWidth * 0.02),
              child: Text(
                trailingText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenHeight * 0.018 * textScaleFactor,
                ),
              ),
            ),
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
