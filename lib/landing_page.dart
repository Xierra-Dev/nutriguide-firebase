import 'package:flutter/material.dart';
import 'package:nutriguide/account_page.dart';
import 'package:nutriguide/home_page.dart'; // Assuming you have a HomePage
import 'package:nutriguide/personalization_page.dart'; // Assuming you have a PersonalizationPage
import 'dart:async';
import 'login_page.dart';
import 'register_page.dart';
import 'services/themealdb_service.dart';
import 'services/auth_service.dart'; // Import the auth service
import 'permission/notifications_permission.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
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

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  String? _currentImageUrl;
  String? _previousImageUrl;
  bool _isLoading = true;
  final TheMealDBService _mealService = TheMealDBService();
  final AuthService _authService = AuthService(); // Add AuthService instance
  Timer? _imageChangeTimer;
  AnimationController? _controller;
  Animation<double>? _animation;

  NotificationsServices notificationsServices = NotificationsServices();

  @override
  void initState() {
    super.initState();

    // Existing initialization code remains the same
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );

    _loadRandomMealImage();
    notificationsServices.requestNotificationPermission();

    _imageChangeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadRandomMealImage();
    });
  }

  @override
  void dispose() {
    _imageChangeTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadRandomMealImage() async {
    try {
      final imageUrl = await _mealService.getRandomMealImage();
      if (mounted) {
        _controller?.reset();
        setState(() {
          _previousImageUrl = _currentImageUrl;
          _currentImageUrl = imageUrl;
          _isLoading = false;
        });
        _controller?.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Previous image (fading out)
          if (_previousImageUrl != null)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_previousImageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          // Current image (fading in)
          if (_currentImageUrl != null && _animation != null)
            FadeTransition(
              opacity: _animation!,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_currentImageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),
          // Fallback image
          if (_currentImageUrl == null && _previousImageUrl == null)
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/landing_page.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Content with animations
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 800),
                      opacity: _isLoading ? 0.0 : 1.0,
                      child: Text(
                        'Plan\nYour\nFood',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pacifico',
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              SlideLeftRoute(page: const RegisterPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 106, 0),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              SlideLeftRoute(page: const LoginPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 42, 227, 206),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Divider with OR text
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: const Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white70)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10), // Spacing between divider and Google button
                      // Google Sign-In Button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final userCredential = await _authService.signInWithGoogle();
                              if (userCredential != null && mounted) {
                                // Check if this is first-time login
                                bool isFirstTime = await _authService.isFirstTimeLogin();

                                // Navigate based on first-time login status
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => isFirstTime
                                        ? const PersonalizationPage()
                                        : const HomePage(),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Error signing in with Google: ${e.toString()}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 55),
                          child: Text(
                            'By using NutriGuide you agree to our\nTerms and Privacy Policy',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}