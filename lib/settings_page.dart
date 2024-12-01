import 'package:flutter/material.dart';
import '/profile_page.dart';
import 'services/auth_service.dart'; // Contoh layanan autentikasi
import 'services/firestore_service.dart'; // Contoh layanan Firestore

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
        ) => page,
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
          curve: Curves.easeOutQuad, // You can change the curve for different animation feels
        ),),
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
    final firestoreService = FirestoreService();

    email = await authService.getCurrentUserEmail();
    username = await authService.getCurrentUsername();

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
                      // Navigate back
                      Navigator.of(context).pop(
                          SlideRightRoute(page: const ProfilePage())
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
                leading: const Icon(Icons.account_circle, color: Colors.white, size: 36),
                title: Text(
                  email ?? 'Loading...',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                onTap: () {
                  // Navigate to Account page
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white, size: 36),
                title: Text(
                  username ?? 'Loading...',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                onTap: () {
                  // Navigate to Profile page
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.white, size: 36),
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                onTap: () {
                  // Navigate to Notifications page
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white, size: 36),
                title: const Text(
                  'Preferences',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                onTap: () {
                  // Navigate to Preferences page
                },
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.white, size: 36),
                title: const Text(
                  'About NutriGuide',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                onTap: () {
                  // Navigate to About NutriGuide page
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}