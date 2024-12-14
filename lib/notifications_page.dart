// notifications_page.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _toggleNotifications() async {
    if (_notificationsEnabled) {
      openAppSettings(); // Buka pengaturan aplikasi untuk menonaktifkan notifikasi
    } else {
      final status = await Permission.notification.request();
      setState(() {
        _notificationsEnabled = status.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enable push notifications now to get personalized recipe ideas, feature updates, and access to NutriGuide offers.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text(
                'Push Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) => _toggleNotifications(),
                activeColor: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}