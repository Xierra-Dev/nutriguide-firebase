import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'services/auth_service.dart';
import 'landing_page.dart';
import 'personalization_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';

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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
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

  ErrorDetails _getErrorDetails(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('The supplied auth credential is incorrect')) {
      return ErrorDetails(
        title: 'Double Check Your Email and Password',
        message: null,
        imagePath: 'assets/images/double-check-password-email.png',
      );
    } else if (errorStr.contains('A network error')) {
      return ErrorDetails(
        title: 'No Internet Connection',
        message: 'Network error. Please check your internet connection.',
        imagePath: 'assets/images/no-internet.png',
      );
    } else if (errorStr.contains('email-not-verified')) {
      return ErrorDetails(
        title: 'EMAIL NOT VERIFIED',
        message: 'Please verify your email first. Check your inbox for verification link.',
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
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
          ),
          child: Container(
            padding: EdgeInsets.all(Dimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  specificImage ?? 'assets/images/error-occur.png',
                  height: 100,
                  width: 100,
                ),
                SizedBox(height: Dimensions.spacingL),
                Text(
                  title ?? 'AN ERROR OCCURRED',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  SizedBox(height: Dimensions.spacingM),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: Dimensions.spacingL),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.8),
                AppColors.primary,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Logo and Welcome Text
                  Container(
                    padding: EdgeInsets.all(Dimensions.paddingXL),
                    child: Column(
                      children: [
                        // App Logo
                        Container(
                          padding: EdgeInsets.all(Dimensions.paddingL),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_NutriGuide.png',
                            width: 80,
                            height: 80,
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingL),
                        // Welcome Text
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading1),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.25),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Dimensions.spacingM),
                        Text(
                          'Sign in to continue your nutrition journey',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Login Form Container
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingL),
                    padding: EdgeInsets.all(Dimensions.paddingL),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Field with enhanced styling
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.primary,
                                size: Dimensions.iconM,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),

                          SizedBox(height: Dimensions.spacingL),

                          // Password Field with enhanced styling
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primary,
                                size: Dimensions.iconM,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),

                          SizedBox(height: Dimensions.spacingXL),

                          // Enhanced Login Button
                          Container(
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(Dimensions.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Register Link with enhanced styling
                  Padding(
                    padding: EdgeInsets.all(Dimensions.paddingL),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
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
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}