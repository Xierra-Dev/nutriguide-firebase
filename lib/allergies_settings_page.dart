import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'preference_page.dart';

class AllergiesSettingsPage extends StatefulWidget {
  const AllergiesSettingsPage({super.key});

  @override
  State<AllergiesSettingsPage> createState() => _AllergiesSettingsPageState();
}

class _AllergiesSettingsPageState extends State<AllergiesSettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  Set<String> selectedAllergies = {};
  bool isEditing = false;
  bool _hasChanges = false;

  final List<String> allergies = [
    'Dairy',
    'Eggs',
    'Fish',
    'Shellfish',
    'Tree nuts (e.g., almonds, walnuts, cashews)',
    'Peanuts',
    'Wheat',
    'Soy',
    'Glutten',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllergies();
  }

  Future<void> _loadAllergies() async {
    try {
      final userAllergies = await _firestoreService.getUserAllergies();
      setState(() {
        selectedAllergies = Set.from(userAllergies);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading allergies: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAllergies() async {
    setState(() => isLoading = true);
    try {
      await _firestoreService.saveUserAllergies(selectedAllergies.toList());
      setState(() {
        isEditing = false;
        _hasChanges = false; // Reset perubahan setelah disimpan
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10), // Add some spacing between icon and text
              Text('Health data saved successfully'),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving allergies: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1), // Set textScaleFactor ke 1
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'Allergies',
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
              ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange,))
              : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: allergies.length,
                  itemBuilder: (context, index) {
                    final allergy = allergies[index];
                    final isSelected = selectedAllergies.contains(allergy);
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            allergy,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? Colors.green : Colors.grey,
                            size: 24,
                          ),
                          onTap: isEditing
                              ? () {
                            setState(() {
                              if (isSelected) {
                                selectedAllergies.remove(allergy);
                              } else {
                                selectedAllergies.add(allergy);
                              }
                              _hasChanges = true;
                            });
                          }
                              : null,
                        ),
                        const Divider(
                          color: Colors.grey,
                          height: 1,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _hasChanges ? _saveAllergies : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges
                            ? Colors.deepOrange
                            : Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: isEditing
                              ? Colors.grey[900]
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        setState(() {
                          isEditing = !isEditing;
                          if (!isEditing) {
                            _hasChanges = false; // Reset changes if editing is canceled
                          }
                        });
                      },
                      child: Text(
                        isEditing ? 'CANCEL' : 'EDIT',
                        style: TextStyle(
                          color: isEditing ? Colors.red : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
}
