import 'package:flutter/material.dart';
import 'settings_page.dart';

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

class AboutNutriguidePage extends StatelessWidget {
  const AboutNutriguidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(15.0),
    child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'About NutriGuide',
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
      body: Center(
        child: Container(
          child: Text('NutriGuide v1.0',style: TextStyle(
            fontSize: 20,
            color: Colors.grey.shade800,
          ),
          ),
        ),
      ),
    ),
    );
  }

}
