import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutriguide/landing_page.dart';
import 'package:nutriguide/login_page.dart';
import 'services/auth_service.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final User? user;

  const EmailVerificationPage({
    Key? key,
    required this.email,
    this.user
  }) : super(key: key);

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
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
          curve: Curves.easeOutQuad,
        ),),
        child: child,
      );
    },
  );
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthService _authService = AuthService();
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = true;
  int resendTimeout = 30;
  Timer? resendTimer;

  // New timer-related variables
  late Timer _verificationTimer;
  int _remainingSeconds = 180; // 3 minutes

  @override
  void initState() {
    super.initState();
    isEmailVerified = _authService.isEmailVerified();

    if (!isEmailVerified) {
      _startVerificationTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    resendTimer?.cancel();
    _verificationTimer.cancel();
    super.dispose();
  }

  void _startVerificationTimer() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Periodically check verification status
        await FirebaseAuth.instance.currentUser?.reload();

        setState(() {
          isEmailVerified = _authService.isEmailVerified();
        });

        if (isEmailVerified) {
          timer.cancel();

          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            'emailVerified': true
          });

          // Navigate to next screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        timer.cancel();
        // Handle timeout - maybe show a dialog or option to resend
      }
    });
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();

      setState(() {
        canResendEmail = false;
        _remainingSeconds = 180; // Reset timer
      });

      resendTimer = Timer.periodic(
        const Duration(seconds: 1),
            (timer) {
          if (resendTimeout > 0) {
            setState(() {
              resendTimeout--;
            });
          } else {
            setState(() {
              canResendEmail = true;
              resendTimeout = 30;
            });
            timer.cancel();
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email has been sent'),
          backgroundColor: Colors.green,
        ),
      );

      // Restart the verification timer
      _startVerificationTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sending verification email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Email Verification', style: TextStyle(color: Colors.white),),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Verify your email address',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to:\n${widget.email}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Time remaining: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: canResendEmail ? resendVerificationEmail : null,
                child: Text(
                  canResendEmail
                      ? 'Resend Email'
                      : 'Resend in ${resendTimeout}s',
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Sign out if the user chooses to cancel
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LandingPage()),
                  );
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),
              isEmailVerified
                  ? const Text(
                'Email Verified!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              )
                  : const Text(
                'Waiting for verification...',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}