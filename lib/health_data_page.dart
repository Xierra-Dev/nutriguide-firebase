import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'widgets/custom_number_picker.dart';
import 'widgets/custom_gender_picker.dart';
import 'widgets/custom_activitiyLevel_picker.dart';
import 'preference_page.dart';

class HealthDataPage extends StatefulWidget {
  const HealthDataPage({super.key});

  @override
  State<HealthDataPage> createState() => _HealthDataPageState();
}

class _HealthDataPageState extends State<HealthDataPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;

  // Original values from Firestore
  String? originalGender;
  int? originalBirthYear;
  double? originalHeight;
  double? originalWeight;
  String? originalActivityLevel;

  // Editable values
  String? gender;
  int? birthYear;
  String? heightUnit = 'cm';
  double? height;
  double? weight;
  String? activityLevel;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      final userData = await _firestoreService.getUserPersonalization();
      if (mounted) {
        setState(() {
          // Save original values
          originalGender = userData?['gender'];
          originalBirthYear = userData?['birthYear'];
          originalHeight = userData?['height'];
          originalWeight = userData?['weight'];
          originalActivityLevel = userData?['activityLevel'];

          // Set current values
          gender = originalGender;
          birthYear = originalBirthYear;
          height = originalHeight;
          weight = originalWeight;
          activityLevel = originalActivityLevel;

          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading health data: $e');
      if (mounted) {
        setState(() {
          gender = null;
          birthYear = null;
          height = null;
          weight = null;
          activityLevel = null;
          isLoading = false;
        });
      }
    }
  }

  bool get _hasChanges {
    return gender != originalGender ||
        birthYear != originalBirthYear ||
        height != originalHeight ||
        weight != originalWeight ||
        activityLevel != originalActivityLevel;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      bool? shouldExit = await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "Dismiss",
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: const Text(
                          'Any unsaved data\nwill be lost',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(1.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 21.5),
                    const Text(
                      'Are you sure you want leave this page\nbefore you save your data changes?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textScaler: TextScaler.linear(1.0),
                    ),
                    const SizedBox(height: 37),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PreferencePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Leave Page',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textScaler: TextScaler.linear(1.0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textScaler: TextScaler.linear(1.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      return shouldExit ?? false;
    } else {
      return true;
    }
  }

  void _onBackPressed(BuildContext context) {
    if (_hasChanges) {
      _onWillPop();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Health Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textScaler: TextScaler.linear(1.0),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _onBackPressed(context),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
            : Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    _buildDataItem('Sex', gender ?? 'Not Set', _editSex),
                    _buildDataItem('Year of Birth', birthYear?.toString() ?? 'Not Set', _editYearOfBirth),
                    _buildDataItem('Height', height != null ? '$height cm' : 'Not Set', _editHeight),
                    _buildDataItem('Weight', weight != null ? '$weight kg' : 'Not Set', _editWeight),
                    _buildDataItem('Activity Level', activityLevel ?? 'Not Set', _editActivityLevel),
                  ],
                ),
              ),
            ),
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.disabled)) {
                        return Colors.grey.shade800;
                      }
                      return Colors.deepOrange;
                    }),
                    animationDuration: const Duration(milliseconds: 300),
                    minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  onPressed: _hasChanges ? _saveHealthData : null,
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      color: _hasChanges ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textScaler: TextScaler.linear(1.0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String label, String value, VoidCallback onEdit) {
    final bool isNotSet = value == 'Not Set';

    return Column(
      children: [
        ListTile(
          title: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textScaler: TextScaler.linear(1.0),
          ),
          trailing: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isNotSet ? Colors.red : Colors.white,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.linear(1.0),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: const Offset(16, 0),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(
            color: Colors.grey,
            height: 1,
          ),
        ),
      ],
    );
  }

  Future<void> _saveHealthData() async {
    setState(() => isLoading = true);
    try {
      await _firestoreService.saveUserPersonalization({
        'gender': gender,
        'birthYear': birthYear,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Health data saved successfully'),
            ],
          ),
        ),
      );

      setState(() {
        originalGender = gender;
        originalBirthYear = birthYear;
        originalHeight = height;
        originalWeight = weight;
        originalActivityLevel = activityLevel;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving health data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _editSex() {
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

  void _editYearOfBirth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'What year were you born in?',
          unit: '',
          initialValue: birthYear?.toDouble(),
          minValue: 1900,
          maxValue: 2045,
          onValueChanged: (value) {
            setState(() => birthYear = value.toInt());
          },
        ),
      ),
    );
  }

  void _editHeight() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your height',
          unit: 'cm',
          initialValue: height,
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

  void _editWeight() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your weight',
          unit: 'kg',
          initialValue: weight,
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

  void _editActivityLevel() {
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
}
