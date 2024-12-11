import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'widgets/custom_number_picker.dart';
import 'widgets/custom_gender_picker.dart';
import 'widgets/custom_activitiyLevel_picker.dart';
import 'goals_page.dart';
import 'home_page.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'services/themealdb_service.dart';

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  _PersonalizationPageState createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String? gender;
  int? birthYear;
  String heightUnit = 'cm';
  double? height;
  double? weight;
  String? activityLevel;
  bool _isLoading = false;
  int currentStep = 0;
  final TheMealDBService _mealService = TheMealDBService();
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _loadRandomMealImage();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? userData = await _firestoreService.getUserPersonalization();
      if (userData != null) {
        setState(() {
          gender = userData['gender'] as String?;
          birthYear = userData['birthYear'] as int?;
          heightUnit = userData['heightUnit'] as String? ?? 'cm';
          height = (userData['height'] as num?)?.toDouble();
          weight = (userData['weight'] as num?)?.toDouble();
          activityLevel = userData['activityLevel'] as String?;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    } finally {
      if (mounted) { // Tambahkan mounted check
        setState(() => _isLoading = false);
      }
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
              // Gradient box in center with goals
              Positioned(
                top: 128,  // Adjust this value as needed
                left: 5,
                right: 5,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 45,
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
                      const Text(
                        'REVIEW YOUR HEALTH DATA',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 23.5,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Your data will be used for your personalization.\nPlease review before proceeding',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12.25,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildField('Sex', gender, _showGenderDialog),
                      _buildField('Year of Birth', birthYear?.toString(), _showBirthYearDialog),
                      _buildField('Height', height != null ? '$height ${heightUnit == 'cm' ? 'cm' : 'ft'}' : null, _showHeightDialog),
                      _buildField('Weight', weight != null ? '$weight kg' : null, _showWeightDialog),
                      _buildField('Activity Level', activityLevel, _showActivityLevelDialog),
                    ],
                  ),
                ),
              ),

              // Progress bar
              Positioned(
                bottom: 255, // Adjust this value as needed
                left: 0,
                right: 0,
                child: LinearProgressBar(
                  maxSteps: 3,
                  progressType: LinearProgressBar.progressTypeDots,
                  currentStep: currentStep,
                  progressColor: kPrimaryColor,
                  backgroundColor: kColorsGrey400,
                  dotsAxis: Axis.horizontal,
                  dotsActiveSize: 12.5,
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.black,
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
                      TextButton(
                        onPressed:  _showSetUpLaterDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                        child: const Text(
                          'SET UP LATER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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
  }

  Widget _buildField(String label, String? value, VoidCallback onTap) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color.fromARGB(255, 37, 37, 37),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Text(
                    value ?? 'Not Set',
                    style: TextStyle(
                      color: value == null ? Colors.red : Colors.black,
                      fontSize: 18.5,
                      fontWeight: value == null ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 3),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.red, size: 23),
                    onPressed: onTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(
          color: Colors.black,
          height: 3,
          indent: 0,
          endIndent: 0,
        ),
      ],
    );
  }

  void _showGenderDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomGenderPicker(
          initialValue: gender,
        ),
      ),
    ).then((selectedGender) {
      if (selectedGender != null) {
        setState(() {
          gender = selectedGender;
        });
      }
    });
  }

  void _showBirthYearDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'What year were you born in?',
          unit: '',
          initialValue: 2000,
          minValue: 1900,
          maxValue: 2099,
          onValueChanged: (value) {
            setState(() => birthYear = value.toInt());
          },
        ),
      ),
    );
  }

  void _showHeightDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your height',
          unit: 'cm',
          initialValue: 100,
          minValue: 0,
          maxValue: 999,
          showDecimals: true,
          onValueChanged: (value) {
            setState(() => height = value);
          },
        ),
      ),
    );
  }

  void _showWeightDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your weight',
          unit: 'kg',
          initialValue: 50,
          minValue: 0,
          maxValue: 999,
          showDecimals: true,
          onValueChanged: (value) {
            setState(() => weight = value);
          },
        ),
      ),
    );
  }

  void _showActivityLevelDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomActivityLevelPicker(
          initialValue: activityLevel,
        ),
      ),
    ).then((selectedActivityLevel) {
      if (selectedActivityLevel != null) {
        setState(() {
          activityLevel = selectedActivityLevel;
        });
      }
    });
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.saveUserPersonalization({
        'gender': gender,
        'birthYear': birthYear,
        'heightUnit': heightUnit,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
      });

      // Navigate to GoalsPage after successful save
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GoalsPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

const kPrimaryColor = Colors.red;
const kColorsGrey400 = Colors.orangeAccent;
