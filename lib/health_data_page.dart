import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'widgets/custom_number_picker.dart';
import 'widgets/custom_gender_picker.dart';
import 'widgets/custom_activitiyLevel_picker.dart';
import 'preference_page.dart';

class HealthDataPage extends StatefulWidget {
  const HealthDataPage({Key? key}) : super(key: key);

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
  int birthYear = 2000;
  String heightUnit = 'cm';
  double height = 170;
  double weight = 70;
  String activityLevel = 'Not active';

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    try {
      final userData = await _firestoreService.getUserPersonalization();
      if (userData != null) {
        setState(() {
          // Save original values
          originalGender = userData['gender'];
          originalBirthYear = userData['birthYear'];
          originalHeight = userData['height'];
          originalWeight = userData['weight'];
          originalActivityLevel = userData['activityLevel'];

          // Set current values
          gender = originalGender;
          birthYear = originalBirthYear ?? 2000;
          height = originalHeight ?? 170;
          weight = originalWeight ?? 70;
          activityLevel = originalActivityLevel ?? 'Not active';

          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading health data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Check if any changes have been made
  bool get _hasChanges {
    return gender != originalGender ||
        birthYear != originalBirthYear ||
        height != originalHeight ||
        weight != originalWeight ||
        activityLevel != originalActivityLevel;
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      // Jika ada perubahan, tampilkan dialog konfirmasi
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
                width: MediaQuery.of(context).size.width * 0.9, // Lebar 90% dari layar
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Warna latar belakang gelap
                  borderRadius: BorderRadius.circular(28), // Sudut yang lebih bulat
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min ,
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
                    ),
                    const SizedBox(height: 37),
                    // Tombol disusun secara vertikal
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      return shouldExit ?? false; // Pastikan selalu mengembalikan bool
    } else {
      // Jika tidak ada perubahan, langsung keluar
      return true;
    }
  }

  void _onBackPressed(BuildContext context) {
    if (_hasChanges) {
      // Jika ada perubahan yang belum disimpan, panggil _onWillPop
      _onWillPop();
    } else {
      Navigator.pop(context); // Jika tidak ada perubahan, cukup navigasi kembali
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Mencegah navigasi kembali sebelum konfirmasi
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
                    _buildDataItem('Sex', gender ?? 'Not set', _editSex),
                    _buildDataItem('Year of Birth', birthYear.toString(), _editYearOfBirth),
                    _buildDataItem('Height', '$height cm', _editHeight),
                    _buildDataItem('Weight', '$weight kg', _editWeight),
                    _buildDataItem('Activity Level', activityLevel, _editActivityLevel),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanges
                      ? Colors.deepOrange
                      : Colors.grey,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: isLoading && _hasChanges ? null : _saveHealthData,
                child: Text(
                  'SAVE',
                  style: TextStyle(
                    color: _hasChanges ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDataItem(String label, String value, VoidCallback onEdit) {
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
          ),
          trailing: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end, // Align content to the end
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: const Offset(16, 0), // Shift edit icon to the right
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
        const SnackBar(content: Text('Health data saved successfully')),

      );

      // Update original values after successful save
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
    // Implement edit functionality
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
    // Implement edit functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'What year were you born in?',
          unit: '',
          initialValue: birthYear.toDouble(),
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
    // Implement edit functionality
    Navigator.of(context).push(
        MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
        title: 'Your height',
        unit: 'cm',
        initialValue: height,
        minValue: 100,
        maxValue: 250,
        onValueChanged: (value) {            setState(() => height = value);
        },
        ),
        ),
    );
  }

  void _editWeight() {
    // Implement edit functionality
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomNumberPicker(
          title: 'Your weight',
          unit: 'kg',
          initialValue: weight,
          minValue: 30,
          maxValue: 200,
          showDecimals: true,
          onValueChanged: (value) {
            setState(() => weight = value);
          },
        ),
      ),
    );
  }

  void _editActivityLevel() {
    // Implement edit functionality
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


