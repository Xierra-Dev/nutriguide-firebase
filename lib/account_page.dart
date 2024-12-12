import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:nutriguide/landing_page.dart';
import 'settings_page.dart';
import 'services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

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

class _AccountPageState extends State<AccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? email;
  String displayPassword = '********';
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  bool isGoogleUser() {
    User? user = _auth.currentUser;
    return user?.providerData.any((userInfo) =>
    userInfo.providerId == 'google.com') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authService = AuthService();

    try {
      email = authService.getCurrentUserEmail();
      setState(() {});
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e'),
          backgroundColor: Colors.red,),
      );
    }
  }

  Future<void> changeEmail() async {
    if (_currentPasswordController.text.isEmpty ||
        _newEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(
        _newEmailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email format')),
      );
      return;
    }

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Reauthenticate user first
        AuthCredential credential = EmailAuthProvider.credential(
            email: currentUser.email!,
            password: _currentPasswordController.text
        );

        await currentUser.reauthenticateWithCredential(credential);

        // Update email
        await currentUser.verifyBeforeUpdateEmail(_newEmailController.text);

        // Reset controllers
        _currentPasswordController.clear();
        _newEmailController.clear();

        // Update email locally
        setState(() {
          email = _newEmailController.text;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email successfully changed'),
            backgroundColor: Colors.green,),
        );
        // Optional: Close email change dialog
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change email: ${e.message}'),
          backgroundColor: Colors.red,),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,),
      );
    }
  }

  void _showChangeEmailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        backgroundColor: Colors.grey[800],
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Change Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: 'New Email',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 12,
                    )
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _currentPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12.5),
                      child: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? MdiIcons.eyeOff : MdiIcons.eye,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 12,
                    )
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: changeEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text(
                      'Change Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmNewPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirmation do not match')),
      );
      return;
    }

    try {
      User? currentUser  = _auth.currentUser ;
      if (currentUser  != null) {
        // Reauthenticate user first
        AuthCredential credential = EmailAuthProvider.credential(
            email: currentUser .email!,
            password: _currentPasswordController.text
        );

        await currentUser .reauthenticateWithCredential(credential);

        // Update password
        await currentUser .updatePassword(_newPasswordController.text);

        // Reset controllers
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password successfully changed'),
            backgroundColor: Colors.green,),
        );

        // Optional: Close password change dialog
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: ${e.message}'),
          backgroundColor: Colors.red,),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e',
        ),
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive text scaling
          final textScaleFactor = mediaQuery.textScaleFactor;
          final responsiveWidth = screenWidth * 0.85;
          final responsiveHeight = screenHeight * 0.47;

          // Adaptive padding and spacing
          final double baseWidth = 375; // iPhone 12 Pro width as base
          final double widthRatio = screenWidth / baseWidth;
          final double scaleFactor = widthRatio.clamp(0.8, 1.2);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              width: responsiveWidth,
              height: responsiveHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: Color(0xFF2C2C2C),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 20 * scaleFactor,
                        horizontal: 25 * scaleFactor
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange[800],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Change Password',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 21 * textScaleFactor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          MdiIcons.keyChange,
                          color: Colors.black,
                          size: 29 * scaleFactor,
                        ),
                      ],
                    ),
                  ),

                  // Password Fields Section
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 30.0 * scaleFactor,
                        left: 15.0 * scaleFactor,
                        right: 15.0 * scaleFactor,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildAdaptivePasswordField('Current Password', _currentPasswordController, scaleFactor, textScaleFactor),
                            SizedBox(height: 15 * scaleFactor),
                            _buildAdaptivePasswordField('New Password', _newPasswordController, scaleFactor, textScaleFactor),
                            SizedBox(height: 15 * scaleFactor),
                            _buildAdaptivePasswordField('Confirm New Password', _confirmNewPasswordController, scaleFactor, textScaleFactor),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons Section
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 25 * scaleFactor,
                      left: 15 * scaleFactor,
                      right: 15 * scaleFactor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange[800],
                              padding: EdgeInsets.symmetric(vertical: 15 * scaleFactor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0),
                              ),
                              elevation: 6,
                            ),
                            child: Text(
                              'Change Password',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13 * textScaleFactor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15 * scaleFactor),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15 * scaleFactor),
                              side: BorderSide(color: Colors.deepOrange[800]!, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.deepOrange[800],
                                fontSize: 13 * textScaleFactor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.7,
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
          );
        },
      ),
    );
  }

  Widget _buildAdaptivePasswordField(
      String label,
      TextEditingController controller,
      double scaleFactor,
      double textScaleFactor
      ) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.white,
              fontSize: 14 * textScaleFactor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: Colors.deepOrange),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: 12.5 * scaleFactor),
              child: IconButton(
                icon: Icon(
                  _isPasswordVisible ? MdiIcons.eyeOff : MdiIcons.eye,
                  color: Colors.deepOrange,
                  size: 24 * scaleFactor,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 25 * scaleFactor,
              vertical: 12 * scaleFactor,
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 15 * textScaleFactor,
          ),
        );
      },
    );
  }


  Future<void> confirmLogout(BuildContext context) async {
    final size = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    bool? loggedOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        backgroundColor: Color(0xFF2C2C2C),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.85,
            maxHeight: size.height * 0.4,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.03,
          ),
          decoration: BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logout Icon
              Icon(
                Icons.logout,
                size: size.width * 0.12,
                color: Colors.deepOrange[800],
              ),
              SizedBox(height: size.height * 0.02),

              // Title
              Text(
                'Log Out',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width * 0.06 * textScaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Message
              Text(
                'Are you sure you want to log out of the application?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width * 0.045 * textScaleFactor,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: size.height * 0.04),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange[800],
                        minimumSize: Size(size.width * 0.3, size.height * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.04 * textScaleFactor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: size.width * 0.04),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(size.width * 0.3, size.height * 0.06),
                        side: BorderSide(color: Colors.deepOrange[800]!, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.04 * textScaleFactor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (loggedOut ?? false) {
      try {
        final authService = AuthService();
        await authService.signOut();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logout Failed: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> confirmDeleteAccount(BuildContext context) async {
    bool isGoogle = isGoogleUser();
    final size = MediaQuery.of(context).size;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),  // Increased opacity for better contrast
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),  // Increased border radius
        ),
        backgroundColor: const Color(0xFF2C2C2C),  // Darker, more modern background
        child: Container(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.925,
            maxHeight: size.height * 0.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              SizedBox(height: screenHeight * 0.0225),
              // Title
              const Text(
                'Delete Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: screenHeight * 0.0175),
              // Description
              const Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              SizedBox(height: screenHeight * 0.0225),
              // Input Field
              if (!isGoogle)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _currentPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Enter Password to Confirm',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const Spacer(),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Rest of the code remains the same...
    if (confirmed ?? false) {
      try {
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
            // For email/password users, re-authenticate
            AuthCredential credential = EmailAuthProvider.credential(
                email: currentUser.email!,
                password: _currentPasswordController.text
            );
            await currentUser.reauthenticateWithCredential(credential);

          await currentUser.delete();
          _currentPasswordController.clear();

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LandingPage()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account successfully deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        String errorMessage = 'Failed to delete account';
        if (e is FirebaseAuthException) {
          if (e.code == 'requires-recent-login') {
            errorMessage = 'Please sign in again and retry';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'Incorrect password. Please try again.';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      _currentPasswordController.clear();
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isGoogle = isGoogleUser();
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.0185,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: size.width * 0.02), // Added slight right shift
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: size.width * 0.065,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          SlideRightRoute(page: const SettingsPage()),
                        );
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    SizedBox(width: size.width * 0.04),
                    Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: size.width * 0.055,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.0375),
              ListTile(
                leading: Text(
                  'Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : size.width * 0.042,
                  ),
                ),
                trailing: Container(
                  width: size.width * 0.525,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          email ?? 'Loading...',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : size.width * 0.042,
                          ),
                        ),
                      ),
                      SizedBox(width: size.width * 0.04),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: size.width * 0.055,
                      ),
                    ],
                  ),
                ),
                onTap: isGoogle ? null : _showChangeEmailDialog,
              ),
              SizedBox(height: size.height * 0.025),
              if (!isGoogle) ListTile(
                leading: Text(
                  'Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : size.width * 0.042,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayPassword,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : size.width * 0.042,
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: size.width * 0.055,
                    ),
                  ],
                ),
                onTap: _showChangePasswordDialog,
              ),
              SizedBox(height: size.height * 0.025),
              ListTile(
                leading: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : size.width * 0.042,
                  ),
                ),
                trailing: Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: size.width * 0.062,
                ),
                onTap: () {
                  confirmLogout(context);
                },
              ),
              SizedBox(height: size.height * 0.025),
              ListTile(
                leading: Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: isSmallScreen ? 14 : size.width * 0.042,
                  ),
                ),
                trailing: Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: size.width * 0.07,
                ),
                onTap: () {
                  confirmDeleteAccount(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}