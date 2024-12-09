import 'package:flutter/material.dart';
import 'package:nutriguide/login_page.dart';

class VerificationSuccessDialog extends StatelessWidget {
  const VerificationSuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Verification Successful",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "Your email has been successfully verified. You can now log in to your account.",
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Arahkan ke halaman LoginPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: const Text(
            "Go to Login",
            style: TextStyle(fontSize: 16, color: Colors.deepOrange),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
