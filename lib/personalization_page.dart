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
  final TheMealDBService _mealService = TheMealDBService();
  String? gender;
  int? birthYear;
  String heightUnit = 'cm';
  double? height;
  double? weight;
  String? activityLevel;
  bool _isLoading = false;
  int currentStep = 0;
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _loadRandomMealImage();
    _loadUserData();
  }

  String _truncateText(String? text, {int maxLength = 14}) {
    if (text == null) return 'Not Set';
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}..'
        : text;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    // Disable system text scaling
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: Scaffold(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = MediaQuery.of(context).size;
                final isSmallScreen = size.width < 360;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Stack(
                      children: [
                        _buildMainContent(size, isSmallScreen),
                        _buildProgressBar(size, isSmallScreen),
                        _buildBottomButtons(size, isSmallScreen),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                'REVIEW YOUR HEALTH DATA',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isSmallScreen ? 20 : 23.5,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                textHeightBehavior: TextHeightBehavior(applyHeightToFirstAscent: false),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                'Your data will be used for your personalization.\nPlease review before proceeding',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isSmallScreen ? 10 : 12.25,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                textHeightBehavior: TextHeightBehavior(applyHeightToFirstAscent: false),
              ),
              SizedBox(height: size.height * 0.02),
              ..._buildFields(size, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields(Size size, bool isSmallScreen) {
    return [
      _buildField('Sex', gender, _showGenderDialog, size, isSmallScreen),
      _buildField('Year of Birth', birthYear?.toString(), _showBirthYearDialog, size, isSmallScreen),
      _buildField('Height', height != null ? '$height ${heightUnit == 'cm' ? 'cm' : 'ft'}' : null, _showHeightDialog, size, isSmallScreen),
      _buildField('Weight', weight != null ? '$weight kg' : null, _showWeightDialog, size, isSmallScreen),
      _buildField('Activity Level', activityLevel, _showActivityLevelDialog, size, isSmallScreen),
    ];
  }

  Widget _buildField(String label, String? value, VoidCallback onTap, Size size, bool isSmallScreen) {
    // Truncate the value
    String displayValue = _truncateText(value);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: size.height * 0.01,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 37, 37, 37),
                        fontSize: isSmallScreen ? 18 : 21,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                        child: Text(
                          displayValue,
                          style: TextStyle(
                            color: value == null ? Colors.red : Colors.black,
                            fontSize: isSmallScreen ? 16 : 18.5,
                            fontWeight: value == null ? FontWeight.w600 : FontWeight.w800,
                            height: 1.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textHeightBehavior: const TextHeightBehavior(
                            applyHeightToFirstAscent: false,
                            applyHeightToLastDescent: false,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.01),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.red,
                        size: isSmallScreen ? 20 : 23,
                      ),
                      onPressed: onTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: isSmallScreen ? 15 : 20,
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
      ),
    );
  }

  Widget _buildProgressBar(Size size, bool isSmallScreen) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Positioned(
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
      ),
    );
  }

  Widget _buildBottomButtons(Size size, bool isSmallScreen) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
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
                onPressed: _saveData,
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
                    height: 1.0,
                  ),
                  textHeightBehavior: TextHeightBehavior(applyHeightToFirstAscent: false),
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
                    height: 1.0,
                  ),
                  textHeightBehavior: TextHeightBehavior(applyHeightToFirstAscent: false),
                ),
              ),
            ],
          ),
        ),
      ),
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
