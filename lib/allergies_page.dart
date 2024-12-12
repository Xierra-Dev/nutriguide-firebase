import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'home_page.dart';
import 'services/themealdb_service.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'goals_page.dart';

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
          curve: Curves.easeOutQuad, // You can change the curve for different animation feels
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
      if (mounted) { // Check if widget is still mounted before setting state
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
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 10.0),
          backgroundColor: Color.fromARGB(255, 91, 91, 91),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
              children: [
                Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center text horizontally
                    children: [
                      Text(
                        "Don't Want Our Health\nFeatures?",
                        textAlign: TextAlign.center, // Ensure text is centered
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22.5,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        "To receive personalized meal and recipe recommendations, you need to complete the questionnaire to use Health Features.",
                        textAlign: TextAlign.center, // Ensure text is centered
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        "You can set up later in Settings > Preferences.",
                        textAlign: TextAlign.center, // Ensure text is centered
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,// Center buttons horizontally
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to HomePage
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
                        child: Text("Skip Questionnaire", style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(height: 17.5,),
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
    // Use MediaQuery to get device dimensions and orientation
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final orientation = mediaQuery.orientation;
    final textScaleFactor = mediaQuery.textScaleFactor;

    // Responsive sizing and scaling
    double containerWidth = screenWidth * 0.975;
    double containerHeight = orientation == Orientation.portrait
        ? screenHeight * 0.525
        : screenHeight * 0.75;

    // Responsive font sizes
    double titleFontSize = screenWidth * 0.075;
    double allergyFontSize = screenWidth * 0.04755;
    double buttonFontSize = screenWidth * 0.045;

    // Responsive padding and spacing
    double horizontalPadding = screenWidth * 0.05;
    double verticalPadding = screenHeight * 0.02;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 10),
            decoration: BoxDecoration(
              image: _backgroundImageUrl != null
                  ? DecorationImage(
                image: NetworkImage(_backgroundImageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              )
                  : const DecorationImage(
                image: AssetImage('assets/images/landing_page.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Back Button - Responsive positioning
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: screenWidth * 0.045,
                          top: screenHeight * 0.02
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
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
                    ),
                  ),

                  // Title - Responsive positioning and sizing
                  Positioned(
                    top: screenHeight * 0.075,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Allergies',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Centered Gradient Container - Responsive sizing
                  Positioned(
                    top: screenHeight * 0.145,
                    left: 5,
                    right: 5,
                    child: Center(
                      child: Container(
                        width: containerWidth,
                        height: containerHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.8),
                              const Color.fromARGB(255, 66, 66, 66),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: allergies.map((allergy) =>
                                _buildAllergyOption(allergy, allergyFontSize)
                            ).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Progress Indicator - Responsive positioning
                  Positioned(
                    bottom: screenHeight * 0.25,
                    left: 0,
                    right: 0,
                    child: LinearProgressBar(
                      maxSteps: 3,
                      progressType: LinearProgressBar.progressTypeDots,
                      currentStep: currentStep,
                      progressColor: kPrimaryColor,
                      backgroundColor: kColorsGrey400,
                      dotsAxis: Axis.horizontal,
                      dotsActiveSize: screenWidth * 0.035,
                      dotsInactiveSize: screenWidth * 0.025,
                      dotsSpacing: const EdgeInsets.only(right: 10),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      semanticsLabel: "Label",
                      semanticsValue: "Value",
                      minHeight: 10,
                    ),
                  ),

                  // Bottom Buttons - Responsive sizing and positioning
                  Positioned(
                    bottom: screenHeight * 0.05,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _saveAllergies,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                minimumSize: Size(screenWidth * 0.9, screenHeight * 0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.0125)
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.amber)
                                : Text(
                              'SAVE',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          TextButton(
                            onPressed: _showSetUpLaterDialog,
                            style: TextButton.styleFrom(
                                minimumSize: Size(screenWidth * 0.9, screenHeight * 0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                side: BorderSide(color: Colors.white),
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.0125)
                            ),
                            child: Text(
                              'SET UP LATER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w700,
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
        );
      },
    );
  }

  Widget _buildAllergyOption(String allergy, double fontSize) {
    final bool isSelected = selectedAllergies.contains(allergy);

    return InkWell(
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
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                allergy,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle,
              color: isSelected ? Colors.green : const Color.fromARGB(255, 124, 93, 93),
              size: fontSize * 1.4,
            ),
          ],
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
