import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'allergies_page.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'home_page.dart';
import 'personalization_page.dart';
import 'services/themealdb_service.dart';


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
      setState(() {
      });
    }
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

  Future<void> _loadUserData() async {

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
                        child: Text("Skip Questionnaire",
                          style: TextStyle(
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

  final List<Map<String, dynamic>> goals = [
    {
      'title': 'Weight Less',
      'icon': Icons.scale,
      'size': 25.0,  // Memastikan nilai double bukan null
      'titleSize': 20.0,  // Memastikan nilai double bukan null
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
    // Get device screen size and orientation
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final orientation = mediaQuery.orientation;

    // Responsive font sizes
    final titleFontSize = screenWidth * 0.07;
    final goalTitleFontSize = screenWidth * 0.03875;
    final buttonFontSize = screenWidth * 0.045;

    // Responsive padding and spacing
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.02;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
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
                  // Back Button
                  Positioned(
                    top: verticalPadding,
                    left: horizontalPadding,
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
                  ),

                  // Title
                  Positioned(
                    top: screenHeight * 0.1,
                    left: horizontalPadding,
                    right: horizontalPadding,
                    child: Text(
                      'What are your current goals?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Goals Container
                  Positioned(
                    top: screenHeight * 0.2475,
                    left: horizontalPadding,
                    right: horizontalPadding,
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.85),
                            const Color.fromARGB(255, 66, 66, 66)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: goals.map((goal) => _buildGoalOption(goal, goalTitleFontSize)).toList(),
                      ),
                    ),
                  ),

                  // Progress Bar
                  Positioned(
                    bottom: screenHeight * 0.23,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: LinearProgressBar(
                        maxSteps: 3,
                        progressType: LinearProgressBar.progressTypeDots,
                        currentStep: currentStep,
                        progressColor: kPrimaryColor,
                        backgroundColor: kColorsGrey400,
                        dotsAxis: Axis.horizontal,
                        dotsActiveSize: screenWidth * 0.03,
                        dotsInactiveSize: screenWidth * 0.025,
                        dotsSpacing: const EdgeInsets.only(right: 10),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                        semanticsLabel: "Label",
                        semanticsValue: "Value",
                        minHeight: 10,
                      ),
                    ),
                  ),

                  // Buttons
                  Positioned(
                    bottom: verticalPadding,
                    left: horizontalPadding,
                    right: horizontalPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if(selectedGoals.isNotEmpty)
                          ElevatedButton(
                            onPressed: selectedGoals.isNotEmpty ? _saveGoals : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              minimumSize: Size(screenWidth * 0.9, screenHeight * 0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.0125),
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
                        OutlinedButton(
                          onPressed: _showSetUpLaterDialog,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(screenWidth * 0.95, screenHeight * 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.0125),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalOption(Map<String, dynamic> goal, double titleSize) {
    final bool isSelected = selectedGoals.contains(goal['title']);
    final double iconSize = (goal['size'] as double?) ?? 35.0;
    final double textSize = (goal['titleSize'] as double?) ?? 35.0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedGoals.remove(goal['title']);
            } else {
              selectedGoals.add(goal['title'] as String);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(
                goal['icon'] as IconData,
                color: Colors.black,
                size: iconSize,
              ),
              const SizedBox(width: 20),
              Text(
                goal['title'] as String,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                isSelected ? Icons.check_circle : Icons.circle,
                color: isSelected ? Colors.green : const Color.fromARGB(255, 124, 93, 93),
                size: 27.5,
              ),
            ],
          ),
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
