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
  String? username;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authService = AuthService();

    email = authService.getCurrentUserEmail();
    username = authService.getCurrentUsername();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        SlideRightRoute(page: const ProfilePage()),
                      );
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ListTile(
                leading: const Text(
                  'Account',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (email != null && email!.length > 17) ? '${email!.substring(0, 17)}...' : (email ?? 'Loading...'),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    SlideLeftRoute(page: const AccountPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Text(
                  'Profile',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (username != null && username!.length > 17) ? '${username!.substring(0, 17)}...' : (username ?? 'Loading...'),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    SlideLeftRoute(page: const ProfileEditPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                onTap: () {
                  Navigator.of(context).push(
                    SlideLeftRoute(page: const NotificationsPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text(
                  'Preferences',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    SlideLeftRoute(
                      page: const PreferencePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text(
                  'About NutriGuide',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
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
    );
  }


}