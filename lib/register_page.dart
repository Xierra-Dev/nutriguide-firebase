import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'services/auth_service.dart';
import 'landing_page.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'email_verification_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/font_sizes.dart';
import 'core/constants/dimensions.dart';
import 'core/helpers/responsive_helper.dart';

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
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  final AuthService _authService = AuthService();

  bool _isDialogShowing = false;

  void _checkPasswordRequirements(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(value);
      _hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential credential = await _authService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );

        // Langsung arahkan ke EmailVerificationPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _emailController.text.trim(),
              user: credential.user,
            ),
          ),
        );
        
      } catch (e) {
        String? errorMessage;
        String errorTitle = 'AN ERROR OCCUR WHEN REGISTERING TO YOUR ACCOUNT';
        String? specificImage;

        if (e.toString().contains('The email address is already in use')) {
          errorMessage = 'This email is already registered. Please use a different email or log in.';
          errorTitle = 'ACCOUNT ALREADY REGISTERED';
          specificImage = 'assets/images/account-already-registered.png';
        } else if (e.toString().contains('network-request-failed')) {
          errorTitle = 'No Internet Connection';
          errorMessage = 'Network error. Please check your internet connection.';
          specificImage = 'assets/images/no-internet.png';
        }

        _showRegistrationDialog(
          isSuccess: false,
          message: errorMessage,
          title: errorTitle,
          specificImage: specificImage,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRegistrationDialog({
    required bool isSuccess,
    String? message,
    String? title,
    String? specificImage,
    UserCredential? credential,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
          ),
          child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  specificImage ?? (isSuccess
                      ? 'assets/images/register-success.png'
                      : 'assets/images/error-occur.png'),
                  height: 100,
                  width: 100,
                ),
                SizedBox(height: Dimensions.spacingL),
                Text(
                  title ?? (isSuccess 
                      ? 'ACCOUNT SUCCESSFULLY REGISTERED' 
                      : 'AN ERROR OCCURRED'),
                  style: TextStyle(
                    color: isSuccess ? AppColors.success : AppColors.error,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isSuccess) ...[
                  SizedBox(height: Dimensions.spacingM),
                  Text(
                    message ?? 'An error occurred during registration.',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: Dimensions.spacingL),
                ElevatedButton(
                  onPressed: () {
                    if (isSuccess) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmailVerificationPage(
                            email: _emailController.text.trim(),
                            user: credential?.user,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppColors.success : AppColors.error,
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingXL,
                      vertical: Dimensions.paddingM,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                  ),
                  child: Text(
                    isSuccess ? 'Continue' : 'Try Again',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequirementItem(bool isMet, String text) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              isMet ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: isMet ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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

    _passwordController.addListener(() {
      _checkPasswordRequirements(_passwordController.text);
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

  // Enhanced requirement item builder
  Widget _buildEnhancedRequirementItem(bool isMet, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isMet ? AppColors.success : AppColors.error.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMet ? Icons.check : Icons.close,
              size: 12,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? AppColors.success : AppColors.error.withOpacity(0.7),
              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Container(
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
            ),

            // Background pattern
            Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/pattern.png'),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header section with back button and title
                    Container(
                      padding: EdgeInsets.all(Dimensions.paddingL),
                      child: Row(
                        children: [
                          
                          // Title
                          Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main form container
                    Container(
                      margin: EdgeInsets.all(Dimensions.paddingL),
                      padding: EdgeInsets.all(Dimensions.paddingL),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name field with icon
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(
                                  Icons.person_outline,
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
                                fillColor: Colors.white,
                              ),
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              ),
                            ),

                            SizedBox(height: Dimensions.spacingL),

                            // Email field with icon
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
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
                                fillColor: Colors.white,
                              ),
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              ),
                            ),

                            SizedBox(height: Dimensions.spacingL),

                            // Password fields with enhanced styling
                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
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
                                fillColor: Colors.white,
                              ),
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              ),
                              onChanged: (value) {
                                _checkPasswordRequirements(value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (!_hasMinLength) {
                                  return 'Password must be at least 8 characters';
                                }
                                if (!_hasNumber) {
                                  return 'Password must contain at least one number';
                                }
                                if (!_hasSymbol) {
                                  return 'Password must contain at least one symbol';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: Dimensions.spacingL),

                            // Confirm Password field
                            TextFormField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                  size: Dimensions.iconM,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
                                fillColor: Colors.white,
                              ),
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              ),
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

                            // Password requirements
                            Container(
                              padding: EdgeInsets.all(Dimensions.paddingM),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password Requirements:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                                    ),
                                  ),
                                  SizedBox(height: Dimensions.spacingS),
                                  _buildEnhancedRequirementItem(_hasMinLength, 'At least 8 characters'),
                                  _buildEnhancedRequirementItem(_hasNumber, 'Contains a number'),
                                  _buildEnhancedRequirementItem(_hasSymbol, 'Contains a symbol'),
                                ],
                              ),
                            ),

                            SizedBox(height: Dimensions.spacingXL),

                            // Register button with gradient
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
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                  ),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            SizedBox(height: Dimensions.spacingL),

                            // Login link with enhanced styling
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: const Color.fromARGB(179, 0, 0, 0),
                                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                    );
                                  },
                                  child: Text(
                                    'Click Here to Login',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Dispose the new controller
    _passwordController.removeListener(() {
      _checkPasswordRequirements(_passwordController.text);
    });
    super.dispose();
  }
}