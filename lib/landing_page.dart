import 'package:flutter/material.dart';
import 'email_verification_page.dart';
import 'personalization_page.dart';
import 'dart:async';
import 'login_page.dart';
import 'register_page.dart';
import 'services/themealdb_service.dart';
import 'services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  Timer? _imageChangeTimer;
  AnimationController? _controller;
  Animation<double>? _animation;

  NotificationsServices notificationsServices = NotificationsServices();

  @override
  void initState() {
    super.initState();

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

  // Responsive text style method
  TextStyle _responsiveTextStyle(BuildContext context, {
    required double baseSize,
    FontWeight fontWeight = FontWeight.bold,
    List<Color>? gradientColors,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final scaleFactor = screenWidth / 375.0; // Base design width

    // Calculate responsive font size
    double fontSize = baseSize * scaleFactor;
    fontSize = fontSize.clamp(baseSize * 0.5, baseSize * 1.5);

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'Pacifico',
      foreground: Paint()
        ..shader = LinearGradient(
          colors: gradientColors ?? [
            const Color(0xFFFF6A00),
            const Color(0xFF00BFFF),
          ],
        ).createShader(
          Rect.fromLTWH(0.0, 0.0, screenWidth, mediaQuery.size.height),
        ),
      shadows: [
        Shadow(
          offset: const Offset(2, 2),
          blurRadius: 4,
          color: Colors.black.withOpacity(0.4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image Logic (Unchanged)
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

            if (_currentImageUrl == null && _previousImageUrl == null)
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/landing_page.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Logo/Title Section - Centered at Top
                  Expanded(
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Plan',
                              style: _responsiveTextStyle(context, baseSize: 48),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Your',
                              style: _responsiveTextStyle(context, baseSize: 48),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Food',
                              style: _responsiveTextStyle(context, baseSize: 48),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Buttons and Terms - Fixed at Bottom
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth < 600
                              ? 16.0
                              : constraints.maxWidth * 0.2,
                        ),
                        child: Column(
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: TextStyle(
                                    fontSize: 18 * (constraints.maxWidth / 375),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Register'),
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
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: TextStyle(
                                    fontSize: 18 * (constraints.maxWidth / 375),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text('Login'),
                              ),
                            ),

                            // Terms and Privacy Policy
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 800),
                              opacity: _isLoading ? 0.0 : 1.0,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20, bottom: 20),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: 'By using NutriGuide you agree to our\n ',
                                    style: TextStyle(
                                      fontSize: 14 * (constraints.maxWidth / 375),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 14 * (constraints.maxWidth / 375),
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 14 * (constraints.maxWidth / 375),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}