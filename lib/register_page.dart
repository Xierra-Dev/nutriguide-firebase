import 'package:flutter/material.dart';
import 'login_page.dart';
import 'services/auth_service.dart';
import 'personalization_page.dart';
import 'landing_page.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'email_verification_page.dart';

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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // New controller

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isNameEmpty = true;
  bool _isEmailEmpty = true;
  bool _isPasswordEmpty = true;
  bool _isConfirmPasswordEmpty = true;
  bool _isNameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  final AuthService _authService = AuthService();

  bool _isDialogShowing = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        await _authService.updateUserProfile(_nameController.text);

        // Show success dialog
        _showRegistrationDialog(isSuccess: true);
      } catch (e) {
        // Check for specific error scenarios
        String? errorMessage;
        String errorTitle = 'AN ERROR OCCUR WHEN REGISTERING TO YOR ACCOUNT';
        String? specificImage;

        // Common Firebase Auth errors
        if (e.toString().contains('The email address is already in use')) {
          errorMessage = 'This email is already registered. Please use a different email or log in.';
          errorTitle = 'ACCOUNT ALREADY REGISTERED'; // Set specific title for this error
          specificImage = 'assets/images/account-already-registered.png';
        } else if (e.toString().contains('network-request-failed')) {
          errorTitle = 'No Internet Connection';
          errorMessage = 'Network error. Please check your internet connection.';
          specificImage = 'assets/images/no-internet.png';
        }

        // Show error dialog
        _showRegistrationDialog(
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

// Modify _showRegistrationDialog to accept specificImage
  void _showRegistrationDialog({
    required bool isSuccess,
    String? message,
    String? title,
    String? specificImage,
  }) {
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
                contentPadding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: isSuccess ? 65 : 20,  // Increased top padding for success case
                  bottom: isSuccess ? -0 : 20, // Reduced bottom padding for success case
                ),
                content: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,  // Center alignment
                      children: [
                        SizedBox(height: isSuccess ? 0 : 30),  // Removed initial spacing for success case
                        Image.asset(
                          specificImage ??
                              (isSuccess
                                  ? 'assets/images/register-success.png'
                                  : 'assets/images/error-occur.png'),
                          height: isSuccess ? 100 : 100,
                          width: isSuccess ? 100 : 100,
                        ),
                        SizedBox(height: isSuccess ? 10 : 15),  // Reduced spacing for success case
                        Text(
                          title ?? (isSuccess ? 'ACCOUNT SUCCESSFULLY REGISTERED' : 'AN ERROR OCCURRED WHEN REGISTERING YOUR ACCOUNT'),
                          style: TextStyle(
                            color: isSuccess ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),
                        if (!isSuccess)
                          Text(
                            message ?? 'An error occurred during registration. Please try again.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    if(!isSuccess)
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
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                actions: isSuccess ? <Widget>[
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isDialogShowing = false;
                        });
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
                        );
                      },
                    ),
                  ),
                ] : null,
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
    _nameController.addListener(_updateNameEmpty);
    _emailController.addListener(_updateEmailEmpty);
    _passwordController.addListener(_updatePasswordEmpty);
    _confirmPasswordController.addListener(_updateConfirmPasswordEmpty);

    // Add focus listeners
    _nameFocusNode.addListener(() {
      setState(() {
        _isNameFocused = _nameFocusNode.hasFocus;
      });
    });

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

    _confirmPasswordFocusNode.addListener(() {
      setState(() {
        _isConfirmPasswordFocused = _confirmPasswordFocusNode.hasFocus;
      });
    });
  }

  // Methods to update empty states
  void _updateNameEmpty() {
    setState(() {
      _isNameEmpty = _nameController.text.isEmpty;
    });
  }

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

  void _updateConfirmPasswordEmpty() {
    setState(() {
      _isConfirmPasswordEmpty = _confirmPasswordController.text.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Image section with custom back button
          Column(
            children: [
              Stack(
                children: [
                  Image.asset(
                    'assets/images/register_page.jpg',
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.43,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text('Failed to load image'),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 45,
                    left: 25,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          SlideRightRoute(
                            page: const LandingPage(), // Replace with the page you want to go back to
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Title Box
          Positioned(
            top: MediaQuery.of(context).size.height * 0.39,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Register',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Form section
          Positioned(
            top: MediaQuery.of(context).size.height * 0.46,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                color: Color.fromRGBO(128, 123, 67, 1),
              ),

              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(25, 45, 25, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                decoration: InputDecoration(
                                  labelText: (_isNameEmpty && !_isNameFocused) ? 'Enter Your Name' : 'Name',
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    borderSide: const BorderSide(color: Colors.deepOrange, width: 1.75,),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 21),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          decoration: InputDecoration(
                            labelText: (_isEmailEmpty && !_isEmailFocused) ? 'Enter Your Email' : 'Email',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: const BorderSide(color: Colors.deepOrange, width: 1.75,),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            // Existing email validation
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 21),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          //obscureText: true,
                          decoration: InputDecoration(
                            labelText: (_isPasswordEmpty && !_isPasswordFocused) ? 'Enter Your Password' : 'Password',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              padding: const EdgeInsets.only(right: 12.5),
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: const BorderSide(color: Colors.deepOrange, width: 1.75,),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 21),
                        // New Password Confirmation Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          //obscureText: true,
                          decoration: InputDecoration(
                            labelText: (_isConfirmPasswordEmpty && !_isConfirmPasswordFocused) ? 'Confirm Your Password' : 'Password',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              padding: const EdgeInsets.only(right: 12.5),
                              icon: Icon(
                                _isConfirmPasswordVisible ? MdiIcons.eyeOff : MdiIcons.eye,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                              borderSide: const BorderSide(color: Colors.deepOrange, width: 1.75,),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 12,
                            ),
                          ),
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 78),
                        ElevatedButton(
                          onPressed:  _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.deepOrange)
                              : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 18.5,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
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
                                  // Navigate to Personalization Page
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Login here',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],//children
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
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Dispose the new controller
    super.dispose();
  }
}