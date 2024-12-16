import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'home_page.dart';
import 'services/themealdb_service.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'goals_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';

class AllergiesPage extends StatefulWidget {
  const AllergiesPage({super.key});

  @override
  _AllergiesPageState createState() => _AllergiesPageState();
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

class _AllergiesPageState extends State<AllergiesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TheMealDBService _mealService = TheMealDBService();
  String? _backgroundImageUrl;
  Set<String> selectedAllergies = {};
  bool _isLoading = false;
  int currentStep = 2;

  @override
  void initState() {
    super.initState();
    _loadRandomMealImage();
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

  final List<String> allergies = [
    'Dairy',
    'Eggs',
    'Fish',
    'Shellfish',
    'Tree nuts (e.g., almonds, walnuts, cashews)',
    'Peanuts',
    'Wheat',
    'Soy',
    'Gluten',
    'Sesame',
    'Corn',
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
                    top: size.height * 0.02,
                    bottom: size.height * 0.15,
                  ),
                  child: Column(
                    children: [
                      // Progress Indicator
                      Container(
                        padding: EdgeInsets.all(Dimensions.paddingM),
                        margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingL),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            LinearProgressBar(
                              maxSteps: 3,
                              currentStep: currentStep,
                              progressColor: Colors.white,
                              backgroundColor: Colors.white24,
                              minHeight: 8,
                            ),
                            SizedBox(height: Dimensions.spacingS),
                            Text(
                              'Final Step',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: Dimensions.spacingXL),

                      // Title Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingL),
                        child: Column(
                          children: [
                            Text(
                              'Any Food Allergies?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: Dimensions.spacingM),
                            Text(
                              'Help us customize your meal recommendations',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: Dimensions.spacingL),

                      // Allergies Container
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingL),
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
                          children: allergies.map((allergy) => _buildAllergyOption(
                            allergy,
                            ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Buttons with Glass Effect
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
                            onPressed: _saveAllergies,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingM),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.button),
                                fontWeight: FontWeight.bold,
                                color: AppColors.surface,
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
                page: const GoalsPage(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(Size size, bool isSmallScreen) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Padding(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Allergies',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isSmallScreen ? 20 : 23.5,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.02),
              SingleChildScrollView(
                child: Column(
                  children: allergies
                      .map((allergy) => _buildAllergyOption(
                    allergy,
                    isSmallScreen ? 16 : 18,
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllergyOption(String allergy, double fontSize) {
    final bool isSelected = selectedAllergies.contains(allergy);
    
    // Map untuk icon alergi
    final Map<String, IconData> allergyIcons = {
      'Dairy': Icons.water_drop_outlined,
      'Eggs': Icons.egg_outlined,
      'Fish': Icons.set_meal_outlined,
      'Shellfish': Icons.catching_pokemon_outlined,
      'Tree nuts (e.g., almonds, walnuts, cashews)': Icons.nature_outlined,
      'Peanuts': Icons.grain_outlined,
      'Wheat': Icons.grass_outlined,
      'Soy': Icons.spa_outlined,
      'Gluten': Icons.bakery_dining_outlined,
      'Sesame': Icons.emoji_nature_outlined,
      'Corn': Icons.grass,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color.fromARGB(255, 54, 54, 54).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedAllergies.remove(allergy);
              } else {
                selectedAllergies.add(allergy);
              }
            });
          },
          child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingL),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(Dimensions.paddingS),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                  ),
                  child: Icon(
                    allergyIcons[allergy] ?? Icons.warning_outlined,
                    color: isSelected ? AppColors.primary : Colors.grey,
                    size: Dimensions.iconM,
                  ),
                ),
                SizedBox(width: Dimensions.spacingM),
                // Allergy Text
                Expanded(
                  child: Text(
                    allergy,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                // Checkbox Icon
                Container(
                  padding: EdgeInsets.all(Dimensions.paddingXS),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.5),
                    size: Dimensions.iconM,
                  ),
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
      bottom: size.height * 0.215,
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Positioned(
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
              ElevatedButton(
                onPressed: _saveAllergies,
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
                    : Text(
                  'SAVE',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
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
                child: Text(
                  'SET UP LATER',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAllergies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.saveUserAllergies(selectedAllergies.toList());
      // Navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving allergies: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

const kPrimaryColor = Colors.red;
const kColorsGrey400 = Colors.orangeAccent;
