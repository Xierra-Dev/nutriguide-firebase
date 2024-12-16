import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'allergies_page.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'home_page.dart';
import 'personalization_page.dart';
import 'services/themealdb_service.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';


class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  _GoalsPageState createState() => _GoalsPageState();
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
          curve: Curves.easeOutQuad,
        ),),
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

class _GoalsPageState extends State<GoalsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TheMealDBService _mealService = TheMealDBService();
  String? _backgroundImageUrl;
  Set<String> selectedGoals = {};
  bool _isLoading = false;
  int currentStep = 1;

  @override
  void initState() {
    super.initState();
    _loadRandomMealImage();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final userGoals = await _firestoreService.getUserGoals();
      setState(() {
        selectedGoals = Set.from(userGoals);
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() {});
    }
  }

  Future<void> _loadRandomMealImage() async {
    try {
      final imageUrl = await _mealService.getRandomMealImage();
      if (mounted) {
        setState(() {
          _backgroundImageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSetUpLaterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 10.0),
            backgroundColor: Color.fromARGB(255, 91, 91, 91),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Don't Want Our Health\nFeatures?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          "To receive personalized meal and recipe recommendations, you need to complete the questionnaire to use Health Features.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          "You can set up later in Settings > Preferences.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                      bottom: 30,
                      left: 30,
                      right: 30,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: Text(
                            "Skip Questionnaire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                        ),
                        SizedBox(height: 17.5),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: Text(
                            "Return to Questionnaire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
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
        );
      },
    );
  }

  final List<Map<String, dynamic>> goals = [
    {
      'title': 'Weight Less',
      'icon': Icons.scale,
      'size': 25.0,
      'titleSize': 20.0,
    },
    {
      'title': 'Get Healthier',
      'icon': Icons.restaurant,
      'size': 25.0,
      'titleSize': 20.0,
    },
    {
      'title': 'Look Better',
      'icon': Icons.fitness_center,
      'size': 25.0,
      'titleSize': 20.0,
    },
    {
      'title': 'Reduce Stress',
      'icon': Icons.favorite,
      'size': 25.0,
      'titleSize': 20.0,
    },
    {
      'title': 'Sleep Better',
      'icon': Icons.nightlight_round,
      'size': 25.0,
      'titleSize': 20.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.8),
                AppColors.primary,
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Background Pattern
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.03,
                    child: Image.asset(
                      'assets/images/pattern.png',
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                ),

                // Main Content
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: size.height * 0.15,
                  ),
                  child: Column(
                    children: [
                      // Progress and Title Section
                      Container(
                        padding: EdgeInsets.all(Dimensions.paddingL),
                        child: Column(
                          children: [
                            // Progress Indicator
                            Container(
                              padding: EdgeInsets.all(Dimensions.paddingM),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                              ),
                              child: Column(
                                children: [
                                  LinearProgressBar(
                                    maxSteps: 3,
                                    currentStep: currentStep,
                                    progressColor: Colors.deepOrange,
                                    backgroundColor: Colors.white24,
                                    minHeight: 8,
                                  ),
                                  SizedBox(height: Dimensions.spacingS),
                                  Text(
                                    'Step ${currentStep + 1} of 3',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: Dimensions.spacingXL),

                            // Title Section
                            Text(
                              'What are your goals?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: Dimensions.spacingM),
                            Text(
                              'Select all that apply to you',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Goals Container
                      Container(
                        margin: EdgeInsets.all(Dimensions.paddingL),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: goals.map((goal) => _buildGoalOption(goal, goal['titleSize'] as double)).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Buttons
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(Dimensions.paddingL),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Dimensions.radiusXL),
                        topRight: Radius.circular(Dimensions.radiusXL),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _showSetUpLaterDialog,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                                side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                              ),
                            ),
                            child: Text(
                              'Set Up Later',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Dimensions.spacingM),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedGoals.isNotEmpty ? _saveGoals : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                                fontWeight: FontWeight.bold,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildBackButton(Size size) {
    return Positioned(
      top: size.height * 0.02,
      left: size.width * 0.05,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              SlideRightRoute(
                page: const PersonalizationPage(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(Size size, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(
        top: size.height * 0.15,
        bottom: size.height * 0.25,
        left: size.width * 0.02,
        right: size.width * 0.02,
      ),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.02,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.04,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.875),
              const Color.fromARGB(255, 66, 66, 66)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What are your current goals?',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isSmallScreen ? 20 : 23.5,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.02),
              ...goals.map((goal) => _buildGoalOption(goal, isSmallScreen ? 18 : 20.0)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(Map<String, dynamic> goal, double fontSize) {
    final bool isSelected = selectedGoals.contains(goal['title']);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingM,
        vertical: Dimensions.paddingS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedGoals.remove(goal['title']);
              } else {
                selectedGoals.add(goal['title']);
              }
            });
          },
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          child: Container(
            padding: EdgeInsets.all(Dimensions.paddingL),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepOrange.withOpacity(0.1) : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.deepOrange : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Dimensions.paddingS),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepOrange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                  ),
                  child: Icon(
                    goal['icon'] as IconData,
                    color: isSelected ? Colors.deepOrange : Colors.grey,
                    size: Dimensions.iconL,
                  ),
                ),
                SizedBox(width: Dimensions.spacingL),
                Expanded(
                  child: Text(
                    goal['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.deepOrange : Colors.black87,
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.deepOrange,
                    size: Dimensions.iconM,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(Size size, bool isSmallScreen) {
    return Positioned(
      bottom: size.height * 0.225,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
        ),
        child: LinearProgressBar(
          maxSteps: 3,
          progressType: LinearProgressBar.progressTypeDots,
          currentStep: currentStep,
          progressColor: kPrimaryColor,
          backgroundColor: kColorsGrey400,
          dotsAxis: Axis.horizontal,
          dotsActiveSize: isSmallScreen ? 10 : 12.5,
          dotsInactiveSize: isSmallScreen ? 8 : 10,
          dotsSpacing: EdgeInsets.only(
            right: size.width * 0.02,
          ),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
          semanticsLabel: "Label",
          semanticsValue: "Value",
          minHeight: size.height * 0.01,
        ),
      ),
    );
  }

  Widget _buildBottomButtons(Size size, bool isSmallScreen) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.065,
          vertical: size.height * 0.02,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectedGoals.isNotEmpty)
              ElevatedButton(
                onPressed: _saveGoals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(
                    vertical: size.height * 0.0125,
                  ),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.amber)
                    : MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            SizedBox(height: size.height * 0.02),
            TextButton(
              onPressed: _showSetUpLaterDialog,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.0125,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: Colors.white),
                ),
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: Text(
                  'SET UP LATER',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.saveUserGoals(selectedGoals.toList());
      Navigator.pushReplacement(
        context,
        SlideLeftRoute(page: const AllergiesPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goals: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

}const kPrimaryColor = Colors.red;
const kColorsGrey400 = Colors.orangeAccent;
