import 'package:flutter/material.dart';
import 'email_verification_page.dart';
import 'personalization_page.dart'; // Assuming you have a PersonalizationPage
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Hitung ukuran font berdasarkan lebar layar
                          double fontSize = constraints.maxWidth *
                              0.1; // 10% dari lebar layar

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 800),
                                    opacity: _isLoading ? 0.0 : 1.0,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Menghitung fontSize yang responsif berdasarkan lebar layar
                                        double fontSize = constraints.maxWidth *
                                            0.1; // Menggunakan persentase dari lebar layar

                                        // Pastikan ukuran font tidak terlalu kecil atau besar
                                        fontSize = fontSize.clamp(24.0,
                                            48.0); // Minimal 24, maksimal 48

                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Teks "Plan"
                                            Text(
                                              'Plan',
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Pacifico',
                                                foreground: Paint()
                                                  ..shader = LinearGradient(
                                                    colors: [
                                                      Color(
                                                          0xFFFF6A00), // #ff6a00
                                                      Color(
                                                          0xFF00BFFF), // #00bfff
                                                    ],
                                                  ).createShader(
                                                    Rect.fromLTWH(
                                                      0.0,
                                                      0.0,
                                                      constraints.maxWidth,
                                                      constraints.maxHeight,
                                                    ),
                                                  ),
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(2, 2),
                                                    blurRadius: 4,
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                                height: 10), // Spasi antar teks

                                            // Teks "Your"
                                            Text(
                                              'Your',
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Pacifico',
                                                foreground: Paint()
                                                  ..shader = LinearGradient(
                                                    colors: [
                                                      Color(
                                                          0xFFFF6A00), // #ff6a00
                                                      Color(
                                                          0xFF00BFFF), // #00bfff
                                                    ],
                                                  ).createShader(
                                                    Rect.fromLTWH(
                                                      0.0,
                                                      0.0,
                                                      constraints.maxWidth,
                                                      constraints.maxHeight,
                                                    ),
                                                  ),
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(2, 2),
                                                    blurRadius: 4,
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(
                                                height: 10), // Spasi antar teks

                                            // Teks "Food"
                                            Text(
                                              'Food',
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Pacifico',
                                                foreground: Paint()
                                                  ..shader = LinearGradient(
                                                    colors: [
                                                      Color(
                                                          0xFFFF6A00), // #ff6a00
                                                      Color(
                                                          0xFF00BFFF), // #00bfff
                                                    ],
                                                  ).createShader(
                                                    Rect.fromLTWH(
                                                      0.0,
                                                      0.0,
                                                      constraints.maxWidth,
                                                      constraints.maxHeight,
                                                    ),
                                                  ),
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(2, 2),
                                                    blurRadius: 4,
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
                      // Divider with OR text

                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 10),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: 'By using NutriGuide you agree to our ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [
                                      Color(0xFFFF6A00), // Warna oranye
                                      Color(0xFF00BFFF), // Warna biru
                                    ],
                                  ).createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 200.0, 50.0),
                                  ),
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black.withOpacity(
                                        0.5), // Shadow untuk menonjolkan teks
                                  ),
                                ],
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration
                                        .underline, // Garis bawah untuk memberi kesan link
                                    color: Colors
                                        .white, // Warna netral terang agar tetap terlihat
                                  ),
                                ),
                                const TextSpan(
                                  text: ' and ',
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration
                                        .underline, // Garis bawah untuk memberi kesan link
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
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