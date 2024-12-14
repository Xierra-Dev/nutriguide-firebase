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
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authService = AuthService();

    try {
      email = authService.getCurrentUserEmail();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e',
          textScaleFactor: 1.0,
        ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: screenHeight * 0.03,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        SlideRightRoute(page: const SettingsPage()),
                      );
                    },
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.375,
                    ),
                    child: Text(
                      'Account Settings',
                      overflow: TextOverflow.ellipsis,
                      textScaleFactor: 1.0,
                      style: TextStyle(
                        fontSize: screenHeight * 0.03,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                children: [
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Email',
                    trailingText: email ?? '',
                    onTap: () {},
                  ),
                  _buildDivider(screenHeight),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Password',
                    trailingText: displayPassword,
                    onTap: _showChangePasswordDialog,
                  ),
                  _buildDivider(screenHeight),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Logout',
                    trailingText: '',
                    onTap: () => confirmLogout(context),
                  ),
                  _buildDivider(screenHeight),
                  _buildSettingsListTile(
                    context: context,
                    leadingText: 'Delete Account',
                    trailingText: '',
                    onTap: () => confirmDeleteAccount(context),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsListTile({
    required BuildContext context,
    required String leadingText,
    required String trailingText,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      title: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.375,
        ),
        child: Text(
          leadingText,
          overflow: TextOverflow.ellipsis,
          textScaleFactor: 1.0,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
            fontSize: screenHeight * 0.02,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty)
            Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.375,
              ),
              margin: EdgeInsets.only(right: screenWidth * 0.02),
              child: Text(
                trailingText,
                overflow: TextOverflow.ellipsis,
                textScaleFactor: 1.0,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.white70,
                  fontSize: screenHeight * 0.018,
                ),
              ),
            ),
          Icon(
            Icons.arrow_forward_ios,
            color: isDestructive ? Colors.red : Colors.white,
            size: screenHeight * 0.02,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(double screenHeight) {
    return Divider(
      color: Colors.white24,
      height: screenHeight * 0.001,
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

    // Tetapkan textScaleFactor ke 1.0 agar tidak terpengaruh pengaturan font HP
    const double textScaleFactor = 1.0;

    final double baseWidth = 375; // iPhone 12 Pro width as base
    final double widthRatio = screenWidth / baseWidth;
    final double scaleFactor = widthRatio.clamp(0.8, 1.2);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => MediaQuery(
        data: mediaQuery.copyWith(textScaleFactor: textScaleFactor),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          backgroundColor: const Color(0xFF2C2C2C),
          child: IntrinsicWidth(
            child: Container(
              width: screenWidth * 0.925,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Key Change Icon
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: Colors.deepOrange,
                        size: 32,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.0225),
                  // Title
                  Text(
                    'Change Password',
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
                  Text(
                    'Please enter your current password and new password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.0225),
                  // Current Password Field
                  _buildAdaptivePasswordField('Current Password', _currentPasswordController, scaleFactor, textScaleFactor),
                  SizedBox(height: screenHeight * 0.0175),
                  // New Password Field
                  _buildAdaptivePasswordField('New Password', _newPasswordController, scaleFactor, textScaleFactor),
                  SizedBox(height: screenHeight * 0.0175),
                  // Confirm New Password Field
                  _buildAdaptivePasswordField('Confirm New Password', _confirmNewPasswordController, scaleFactor, textScaleFactor),
                  SizedBox(height: screenHeight * 0.0425),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
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
        ),
      ),
    );
  }

  Widget _buildAdaptivePasswordField(
      String label,
      TextEditingController controller,
      double scaleFactor,
      double textScaleFactor,
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
              fontSize: 14 * textScaleFactor, // Pastikan textScaleFactor tetap 1.0
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
            fontSize: 15 * textScaleFactor, // Skala teks tetap konstan
          ),
        );
      },
    );
  }

  Future<void> confirmLogout(BuildContext context) async {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    bool? loggedOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0), // Override text scale factor
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          backgroundColor: const Color(0xFF2C2C2C),
          child: SingleChildScrollView(
            child: IntrinsicWidth(
              child: Container(
                width: screenWidth * 0.925,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange[800]!.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Colors.deepOrange[800],
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.0225),
                    Text(
                      'Log Out',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.0175),
                    Text(
                      'Are you sure you want to log out of the application?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.0425),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Log Out',
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
            content: Text('Logout Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> confirmDeleteAccount(BuildContext context) async {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0), // Override text scale factor
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          backgroundColor: const Color(0xFF2C2C2C),
          child: SingleChildScrollView(
            child: IntrinsicWidth(
              child: Container(
                width: screenWidth * 0.925,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
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
                    ),
                    SizedBox(height: screenHeight * 0.0225),
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
                    _buildAdaptivePasswordField(
                        'Current Password', _currentPasswordController, 1.0, 1.0),
                    SizedBox(height: screenHeight * 0.0425),
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
          ),
        ),
      ),
    );

    if (confirmed ?? false) {
      try {
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: currentUser.email!,
            password: _currentPasswordController.text,
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


}
