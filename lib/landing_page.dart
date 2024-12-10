import 'package:flutter/material.dart';
import 'package:nutriguide/account_page.dart';
import 'dart:async';
import 'login_page.dart';
import 'register_page.dart';
import 'services/themealdb_service.dart';
import 'permission/notifications_permission.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  String? _currentImageUrl;
  String? _previousImageUrl;
  bool _isLoading = true;
  final TheMealDBService _mealService = TheMealDBService();
  Timer? _imageChangeTimer;
  AnimationController? _controller; // Periksa null sebelum digunakan
  Animation<double>? _animation; // Periksa null sebelum digunakan

  NotificationsServices notificationsServices = NotificationsServices();

  @override
  void initState() {
    super.initState();

    // Inisialisasi controller dan animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );

    // Memuat gambar awal
    _loadRandomMealImage();

    // Meminta izin notifikasi
    notificationsServices.requestNotificationPermission();

    // Timer untuk mengganti gambar setiap 5 detik
    _imageChangeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadRandomMealImage();
    });
  }

  @override
  void dispose() {
    _imageChangeTimer?.cancel();
    _controller?.dispose(); // Periksa null sebelum dispose
    super.dispose();
  }

  Future<void> _loadRandomMealImage() async {
    try {
      final imageUrl = await _mealService.getRandomMealImage();
      if (mounted) {
        _controller?.reset(); // Periksa null sebelum reset
        setState(() {
          _previousImageUrl = _currentImageUrl;
          _currentImageUrl = imageUrl;
          _isLoading = false;
        });
        _controller?.forward(); // Periksa null sebelum forward
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
