import 'package:flutter/material.dart';
import 'services/firestore_service.dart';

class GoalsSettingsPage extends StatefulWidget {
  const GoalsSettingsPage({Key? key}) : super(key: key);

  @override
  State<GoalsSettingsPage> createState() => _GoalsSettingsPageState();
}

class _GoalsSettingsPageState extends State<GoalsSettingsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  Set<String> selectedGoals = {};
  bool isEditing = false;

  final List<String> goals = [
    'Weight Less',
    'Get Healthier',
    'Look Better',
    'Reduce Stress',
    'Sleep Better',
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final userGoals = await _firestoreService.getUserGoals();
      setState(() {
        selectedGoals = Set.from(userGoals);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveGoals() async {
    setState(() => isLoading = true);
    try {
      await _firestoreService.saveUserGoals(selectedGoals.toList());
      setState(() => isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goals: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Personalized Goals',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      final isSelected = selectedGoals.contains(goal);
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              goal,
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
                                        selectedGoals.remove(goal);
                                      } else {
                                        selectedGoals.add(goal);
                                      }
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
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: isEditing ? _saveGoals : null,
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              isEditing = !isEditing;
                            });
                          },
                          child: Text(
                            isEditing ? 'Cancel' : 'Edit',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 