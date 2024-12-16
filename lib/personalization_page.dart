import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'widgets/custom_number_picker.dart';
import 'widgets/custom_gender_picker.dart';
import 'widgets/custom_activitiyLevel_picker.dart';
import 'goals_page.dart';
import 'home_page.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
import 'services/themealdb_service.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';


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

                SingleChildScrollView(
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
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                                    semanticsLabel: "Progress",
                                    semanticsValue: "Step ${currentStep + 1} of 3",
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
                              'Tell Us About Yourself',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading2),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: Dimensions.spacingM),
                            Text(
                              'Help us personalize your experience',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Container
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
                          children: [
                            _buildFormField('Gender', gender, Icons.person_outline, _showGenderDialog),
                            _buildFormField('Birth Year', birthYear?.toString(), Icons.cake_outlined, _showBirthYearDialog),
                            _buildFormField('Height', height != null ? '$height cm' : null, Icons.height, _showHeightDialog),
                            _buildFormField('Weight', weight != null ? '$weight kg' : null, Icons.monitor_weight_outlined, _showWeightDialog),
                            _buildFormField('Activity Level', activityLevel, Icons.directions_run, _showActivityLevelDialog),
                          ],
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
                            onPressed: _saveData,
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

    Widget _buildFormField(String label, String? value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(Dimensions.paddingL),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Dimensions.paddingS),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
              ),
              child: Icon(
                icon,
                color: Colors.deepOrange,
                size: Dimensions.iconM,
              ),
            ),
            SizedBox(width: Dimensions.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingXS),
                  Text(
                    value ?? 'Not Set',
                    style: TextStyle(
                      color: value == null ? Colors.grey : Colors.black,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: Dimensions.iconM,
            ),
          ],
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
          horizontal: Dimensions.paddingL,
          vertical: Dimensions.paddingXL,
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
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'REVIEW YOUR HEALTH DATA',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading3),
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Dimensions.spacingM),
            Text(
              'Your data will be used for your personalization.\nPlease review before proceeding',
              style: TextStyle(
                color: AppColors.error,
                fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.bodySmall),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Dimensions.spacingL),
            ..._buildFields(size, isSmallScreen),
          ],
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
    final maxLabelWidth = size.width * 0.175;
    final maxValueWidth = size.width * 0.175;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: Dimensions.paddingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: maxLabelWidth,
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: maxValueWidth,
                    child: Text(
                      value ?? 'Not Set',
                      style: TextStyle(
                        color: value == null ? AppColors.error : AppColors.textPrimary,
                        fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                        fontWeight: value == null ? FontWeight.w600 : FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: Dimensions.spacingXS),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: AppColors.error,
                      size: Dimensions.iconM,
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
        Divider(
          color: AppColors.border,
          height: 3,
        ),
      ],
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
