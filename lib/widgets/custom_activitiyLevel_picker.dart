import 'package:flutter/material.dart';

class CustomActivityLevelPicker extends StatefulWidget {
  final String? initialValue;

  const CustomActivityLevelPicker({
    super.key,
    this.initialValue,
  });

  @override
  _CustomActivityLevelPickerState createState() => _CustomActivityLevelPickerState();
}

class _CustomActivityLevelPickerState extends State<CustomActivityLevelPicker> {
  late String _selectedActivityLevel;

  final List<String> _activityLevels = [
    'Not active',
    'Lightly active',
    'Moderately active',
    'Very active',
    'Heavy active',
  ];

  @override
  void initState() {
    super.initState();
    _selectedActivityLevel = widget.initialValue ?? 'Not active';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Back Button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 10),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Select Your Activity Level',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._activityLevels.map((level) => _buildActivityLevelOption(level)),
                    const Spacer(),
                    Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                          left: 8,
                          right: 8,
                        ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(_selectedActivityLevel);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)
                            ),
                          ),
                          child: const Text(
                              'SAVE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
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
    );
  }

  Widget _buildActivityLevelOption(String level) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _selectedActivityLevel == level
            ? Colors.deepOrange.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          level,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        trailing: Icon(
          _selectedActivityLevel == level
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: _selectedActivityLevel == level
              ? Colors.deepOrange
              : Colors.white70,
        ),
        onTap: () {
          setState(() {
            _selectedActivityLevel = level;
          });
        },
      ),
    );
  }
}