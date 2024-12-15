import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'services/auth_service.dart';
import 'landing_page.dart';
import 'personalization_page.dart';

// Add ErrorDetails and LoginPageStrings classes
class ErrorDetails {
  final String title;
  final String? message;
  final String? imagePath;

  ErrorDetails({
    required this.title,
    this.message,
    this.imagePath,
  });
}

class FixedScaleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const FixedScaleText(
      this.text, {
        Key? key,
        this.style,
        this.textAlign,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

class LoginPageStrings {
  static const String networkErrorTitle = 'No Internet Connection';
  static const String networkErrorMessage = 'Network error. Please check your internet connection.';
  static const String invalidCredentialsTitle = 'Double Check Your Email and Password';
  static const String emailNotVerifiedTitle = 'EMAIL NOT VERIFIED';
  static const String emailNotVerifiedMessage = 'Please verify your email first. Check your inbox for verification link.';
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class SlideRightRoute extends PageRouteBuilder {
  // Keep your existing SlideRightRoute implementation
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
  String _loadingMessage = '';
  DateTime? _lastLoginAttempt;

  // Add new helper methods
  ErrorDetails _getErrorDetails(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('The supplied auth credential is incorrect')) {
      return ErrorDetails(
        title: LoginPageStrings.invalidCredentialsTitle,
        message: null,
        imagePath: 'assets/images/double-check-password-email.png',
      );
    } else if (errorStr.contains('A network error')) {
      return ErrorDetails(
        title: LoginPageStrings.networkErrorTitle,
        message: LoginPageStrings.networkErrorMessage,
        imagePath: 'assets/images/no-internet.png',
      );
    } else if (errorStr.contains('email-not-verified')) {
      return ErrorDetails(
        title: LoginPageStrings.emailNotVerifiedTitle,
        message: LoginPageStrings.emailNotVerifiedMessage,
        imagePath: 'assets/images/email-verification.png',
      );
    }

    return ErrorDetails(
      title: 'AN ERROR OCCUR WHEN LOGGING IN TO YOUR ACCOUNT',
      message: 'Please try again later',
      imagePath: 'assets/images/error-occur.png',
    );
  }

  bool _validateInput() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showLoginDialog(
        isSuccess: false,
        title: 'Invalid Input',
        message: 'Please fill in all fields',
      );
      return false;
    }

    if (!_emailController.text.contains('@')) {
      _showLoginDialog(
        isSuccess: false,
        title: 'Invalid Email',
        message: 'Please enter a valid email address',
      );
      return false;
    }

    return true;
  }

  void _navigateBasedOnLoginStatus(bool isFirstTime) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
        isFirstTime ? const PersonalizationPage() : const HomePage(),
      ),
    );
  }

  void _updateLoadingState(bool isLoading, [String message = '']) {
    setState(() {
      _isLoading = isLoading;
      _loadingMessage = message;
    });
  }

  // Update the _login method
  Future<void> _login() async {
    final now = DateTime.now();
    if (_lastLoginAttempt != null &&
        now.difference(_lastLoginAttempt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastLoginAttempt = now;

    if (!_formKey.currentState!.validate() || !_validateInput()) return;

    try {
      _updateLoadingState(true, 'Signing in...');

      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final isFirstTime = await _authService.isFirstTimeLogin();

      _navigateBasedOnLoginStatus(isFirstTime);

    } catch (e) {
      final errorDetails = _getErrorDetails(e);
      _showLoginDialog(
        isSuccess: false,
        message: errorDetails.message,
        title: errorDetails.title,
        specificImage: errorDetails.imagePath,
      );
    } finally {
      _updateLoadingState(false);
    }
  }

  // Keep your existing methods and overrides
  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateEmailEmpty);
    _passwordController.addListener(_updatePasswordEmpty);

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Keep your existing _showLoginDialog method and build method
  void _showLoginDialog({
    required bool isSuccess,
    String? message,
    String? title,
    String? specificImage,
  }) {
    if (isSuccess) {
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
        final screenWidth = MediaQuery.of(context).size.width;
        final scaleFactor = screenWidth / 400.0;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
            Center(
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50 * scaleFactor),
                ),
                insetPadding: EdgeInsets.symmetric(
                  horizontal: 10 * scaleFactor,
                  vertical: 40 * scaleFactor,
                ),
                contentPadding: EdgeInsets.all(20 * scaleFactor),
                content: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 30 * scaleFactor),
                        Image.asset(
                          specificImage ?? 'assets/images/error-occur.png',
                          height: 100 * scaleFactor,
                          width: 100 * scaleFactor,
                        ),
                        SizedBox(height: 25 * scaleFactor),
                        FixedScaleText(
                          title ?? 'AN ERROR OCCUR WHEN LOGGING IN TO YOUR ACCOUNT',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 22 * scaleFactor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 25 * scaleFactor),
                        if (message != null)
                          FixedScaleText(
                            message,
                            style: TextStyle(
                              fontSize: 18 * scaleFactor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(height: 20 * scaleFactor),
                      ],
                    ),
                    // Rest of your dialog code remains unchanged
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
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return MediaQuery(
      // This prevents system font scaling
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
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
                top: screenSize.height * 0.395,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  height: screenSize.height * 0.165,
                  decoration: BoxDecoration(
                    color: Colors.lightGreen,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.75),
                    child: FixedScaleText(
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
              ),

              Positioned(
                top: screenSize.height * 0.46,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.06,
                          vertical: 0,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: (_isEmailEmpty && !_isEmailFocused)
                                      ? 'Enter Your Email'
                                      : 'Email',
                                  labelStyle: TextStyle(fontSize: 16),
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: const BorderSide(color: Colors.deepOrange),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 12,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 16),
                                focusNode: _emailFocusNode,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenSize.height * 0.03),

                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: (_isPasswordEmpty && !_isPasswordFocused)
                                      ? 'Enter Your Password'
                                      : 'Password',
                                  labelStyle: const TextStyle(fontSize: 16),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: BorderSide.none,
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
                                  ),
                                ),
                                style: const TextStyle(fontSize: 16),
                                obscureText: !_isPasswordVisible,
                                focusNode: _passwordFocusNode,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenSize.height * 0.15),

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
                                      ? const CircularProgressIndicator(color: Colors.deepOrange)
                                      : const FixedScaleText(
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
                                    const FixedScaleText(
                                      'Already have an account?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RegisterPage(),
                                          ),
                                        );
                                      },
                                      child: const FixedScaleText(
                                        'Register here',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                          Navigator.of(context).pop(
                            SlideRightRoute(
                              page: const LandingPage(),
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
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.4)),
                )
            ],
          ),
        ),
      ),
    );
  }
}
