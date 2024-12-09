import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Import ChangeNotifier

class AuthService extends ChangeNotifier {
  // Ensure AuthService extends ChangeNotifier
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Method to get current user's email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Method to get current user's username (display name)
  String? getCurrentUsername() {
    return _auth.currentUser?.displayName;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update user profile
  Future<void> updateUserProfile(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    notifyListeners(); // Notify listeners to update the UI
  }

  // Handle Firebase Auth exceptions
  FirebaseAuthException _handleAuthException(FirebaseAuthException e) {
    return e;
  }

  // Update display name of the current user
  Future<void> updateDisplayName(String displayName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        notifyListeners(); // Notify listeners after the display name is updated
      } else {
        throw 'No authenticated user found';
      }
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload(); // Refresh user state
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Error sending verification email: $e');
    }
  }

  // Check if the current user is signed in with Google
  bool isGoogleAccount() {
    final user = _auth.currentUser;
    return user?.providerData.any((info) => info.providerId == 'google.com') ??
        false;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Error sending password reset email: $e');
    }
  }
}
