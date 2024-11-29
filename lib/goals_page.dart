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

  final List<Map<String, dynamic>> goals = [
    {
      'title': 'Weight Less',
      'icon': Icons.scale,
    },
    {
      'title': 'Get Healthier',
      'icon': Icons.restaurant,
    },
    {
      'title': 'Look Better',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Reduce Stress',
      'icon': Icons.favorite,
    },
    {
      'title': 'Sleep Better',
      'icon': Icons.nightlight_round,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 100), // Add smooth transition
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
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, top: 15),
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
                              page: const PersonalizationPage(), // Replace with the page you want to go back to
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Title positioned at top
                const Positioned(
                  top: 55,
                  left: 50,
                  right: 50,
                  child: Text(
                    'What are your current goals?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
        
                // Gradient box in center with goals
                Positioned(
                  top: 212,  // Adjust this value as needed
                  left: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.8),
                          const Color.fromARGB(255, 66, 66, 66)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: goals.map((goal) => _buildGoalOption(goal)).toList(),
                    ),
                  ),
                ),
        
                // Progress bar
                Positioned(
                  bottom: 280, // Adjust this value as needed
                  left: 0,
                  right: 0,
                  child: LinearProgressBar(
                    maxSteps: 3,
                    progressType: LinearProgressBar.progressTypeDots,
                    currentStep: currentStep,
                    progressColor: kPrimaryColor,
                    backgroundColor: kColorsGrey400,
                    dotsAxis: Axis.horizontal,
                    dotsActiveSize: 13.5,
                    dotsInactiveSize: 10,
                    dotsSpacing: const EdgeInsets.only(right: 10),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    semanticsLabel: "Label",
                    semanticsValue: "Value",
                    minHeight: 10,
                  ),
                ),
        
                // Buttons at bottom
                Positioned(
                  bottom: 25,
                  left: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: selectedGoals.isNotEmpty ? _saveGoals : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('SAVE', style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'SET UP LATER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.5,
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
  }

  Widget _buildGoalOption(Map<String, dynamic> goal) {
    final bool isSelected = selectedGoals.contains(goal['title']);

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
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                goal['title'] as String,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.deepOrange : Colors.black,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepOrange,
                    ),
                  ),
                )
                    : null,
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
        MaterialPageRoute(builder: (context) => const AllergiesPage()),
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
}
const kPrimaryColor = Colors.red;
const kColorsGrey400 = Colors.orangeAccent;