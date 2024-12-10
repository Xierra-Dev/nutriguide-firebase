import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cek apakah email belum diverifikasi
      if (!userCredential.user!.emailVerified) {
        // Logout dan lempar pengecualian
        await signOut();
        throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Silakan verifikasi email Anda terlebih dahulu.'
        );
      }

      // Return UserCredential meskipun email belum diverifikasi
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }


  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name jika disediakan
      if (displayName != null) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      // Kirim email verifikasi
      await userCredential.user?.sendEmailVerification();

      // Simpan data pengguna ke Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'timestamp': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      // Jalankan timer untuk memeriksa status verifikasi
      _startVerificationTimer(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  void _startVerificationTimer(User user) {
    Timer(Duration(minutes: 3), () async {
      // Reload user untuk mendapatkan status terbaru
      await user.reload();

      // Periksa apakah email telah diverifikasi
      if (user.emailVerified) {
        // Update status di Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
        });
      } else {
        // Jika belum diverifikasi, hapus user dari Firestore dan Firebase Auth
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update user profile
  Future<void> updateUserProfile(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  // Handle Firebase Auth exceptions
  FirebaseAuthException _handleAuthException(FirebaseAuthException e) {
    return e;
  }

  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
      } else {
        throw 'No authenticated user found';
      }
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }

  Future<bool> waitForEmailVerification({Duration timeout = const Duration(minutes: 3)}) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    final Completer<bool> completer = Completer<bool>();
    final Timer timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    // Listen to user changes
    final subscription = _auth.userChanges().listen((User? updatedUser) {
      if (updatedUser?.emailVerified ?? false) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    try {
      final result = await completer.future;
      return result;
    } finally {
      subscription.cancel();
      timer.cancel(); // Ensure the timer is always cancelled
    }
  }


  // Check if email is verified
  bool isEmailVerified() {
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

  // Custom method to ensure user can only proceed if email is verified
  Future<void> ensureEmailVerified() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('Tidak ada pengguna yang login');
    }

    // Reload user to get the latest verification status
    await user.reload();

    if (!user.emailVerified) {
      // Logout user if email is not verified
      await signOut();
      throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Silakan verifikasi email Anda terlebih dahulu.'
      );
    }
  }

  Future<bool> isFirstTimeLogin() async {
    User? user = _auth.currentUser;
    if (user == null) return true;

    // Menggunakan metadata lastSignInTime untuk mengecek
    return user.metadata.lastSignInTime == user.metadata.creationTime;
  }
}