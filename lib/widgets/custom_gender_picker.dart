import 'package:flutter/material.dart';

class CustomGenderPicker extends StatefulWidget {
  final String? initialValue;

  const CustomGenderPicker({
    super.key,
    this.initialValue,
  });

  @override
  _CustomGenderPickerState createState() => _CustomGenderPickerState();
}

class _CustomGenderPickerState extends State<CustomGenderPicker> {
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialValue ?? 'Male';
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
                  //mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'What sex are you?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGenderOption('Female'),
                    _buildGenderOption('Male'),
                    _buildGenderOption('Prefer not to say'),
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
                            Navigator.of(context).pop(_selectedGender);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)
                            ),
                          ),
                          child: const Text(
                              'SAVE',
                              style: TextStyle(fontSize: 16)
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

  Widget _buildGenderOption(String option) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _selectedGender == option
            ? Colors.deepOrange.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          option,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        trailing: Icon(
          _selectedGender == option
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: _selectedGender == option
              ? Colors.deepOrange
              : Colors.white70,
        ),
        onTap: () {
          setState(() {
            _selectedGender = option;
          });
        },
      ),
    );
  }
}