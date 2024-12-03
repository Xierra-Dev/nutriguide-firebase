import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'services/auth_service.dart';
import 'landing_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
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
          curve: Curves.easeOutQuad, // You can change the curve for different animation feels
        ),),
        child: child,
      );
    },
  );
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isEmailEmpty = true;
  bool _isPasswordEmpty = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isLoading = false;
  bool _isDialogShowing = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );

        // Show success dialog
        _showLoginDialog(isSuccess: true);
      } catch (e) {
        // Check for specific error scenarios
        String? errorMessage; // Change to nullable
        String errorTitle = 'AN ERROR OCCUR WHEN LOGGING IN TO YOUR ACCOUNT'; // Changed title
        String? specificImage;

        // Common Firebase Auth errors
        if (e.toString().contains('The supplied auth credential is incorrect')) {
          errorMessage = null; // Set errorMessage to null
          errorTitle = 'Double Check Your Email and Password'; // Set specific title for this error
          specificImage = 'assets/images/double-check-password-email.png';
        } else if (e.toString().contains('A network error')) {
          errorTitle = 'No Internet Connection';
          errorMessage = 'Network error. Please check your internet connection.';
          specificImage = 'assets/images/no-internet.png';
        } else if (e.toString().contains('user-not-found')) {
          errorMessage = 'Please register your account first'; // Set errorMessage to null
          errorTitle = 'ACCOUNT NOT REGISTERED'; // Set specific title for this error
          specificImage = 'assets/images/account-not-registered.png';
        } else {
          errorMessage = 'Please try again later'; // Default error message
        }

        // Show error dialog
        _showLoginDialog(
          isSuccess: false,
          message: errorMessage,
          title: errorTitle, // Use the dynamic title
          specificImage: specificImage, // Pass the specific image
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLoginDialog({
    required bool isSuccess,
    String? message,
    String? title,
    String? specificImage,
  }) {
    if (isSuccess) {
      // Directly navigate to login page without showing a dialog
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      return;
    }

    setState(() {
      _isDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Semi-transparent overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
            // Dialog
            Center(
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
                contentPadding: const EdgeInsets.all(20),
                content: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 30),
                        Image.asset(
                          specificImage ?? 'assets/images/error-occur.png',
                          height: 100,
                          width: 100,
                        ),
                        const SizedBox(height: 25),
                        Text(
                          title ?? 'AN ERROR OCCUR WHEN LOGGING IN TO YOUR ACCOUNT',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25), // Increased from 20 to 35 for more spacing
                        if (message != null) // Only show if message exists
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        const SizedBox(height: 20), // Added bottom padding
                      ],
                    ),
                    Positioned(
                      top: -2,
                      right: 7,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDialogShowing = false;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isDialogShowing = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers
    _emailController.addListener(_updateEmailEmpty);
    _passwordController.addListener(_updatePasswordEmpty);

    // Add focus listeners
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  // Methods to update empty states
  void _updateEmailEmpty() {
    setState(() {
      _isEmailEmpty = _emailController.text.isEmpty;
    });
  }

  void _updatePasswordEmpty() {
    setState(() {
      _isPasswordEmpty = _passwordController.text.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final formTopPosition = screenSize.height * 0.35; // Position for form

    return Scaffold(
      body: SizedBox(
        height: screenSize.height,
        child: Stack(
          children: [
            // Image Container (positioned at top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: screenSize.height * 0.43,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/register_page.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.39,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.lightGreen,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Login Form Container (positioned independently)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.46,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                    padding:  const EdgeInsets.fromLTRB(25, 0, 25, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                              labelText: (_isEmailEmpty && !_isEmailFocused) ? 'Enter Your Email' : 'Email',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: const BorderSide(color: Colors.deepOrange,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 12,
                              )
                          ),
                          focusNode: _emailFocusNode, // Add this
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                              labelText: (_isPasswordEmpty && !_isPasswordFocused) ? 'Enter Your Password' : 'Password',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: const BorderSide(color: Colors.deepOrange,
                                ),
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
                          obscureText: !_isPasswordVisible,
                          focusNode: _passwordFocusNode, // Add this
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 145),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18.5,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 0), // Added spacing between text and TextButton
                              TextButton(
                                onPressed: () {
                                  // Navigate to Register Page
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Register here',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ], //children
                    ),
                  ),
                  ),
                  ),
                ),
            ),
            ),
            // Back Button
            Positioned(
              top: 45,
              left: 25,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          SlideRightRoute(
                            page: const LandingPage(), // Replace with the page you want to go back to
                          ),
                        );
                      },
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isDialogShowing)
              Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4),))
          ],
        ),
      ),
    );
  }
}