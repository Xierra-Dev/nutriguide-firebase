import 'package:flutter/material.dart';

class CustomNumberPicker extends StatefulWidget {
  final String title;
  final String unit;
  final double initialValue;
  final double minValue;
  final double maxValue;
  final bool showDecimals;
  final Function(double) onValueChanged;

  const CustomNumberPicker({
    super.key,
    required this.title,
    required this.unit,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    this.showDecimals = false,
    required this.onValueChanged,
  });

  @override
  _CustomNumberPickerState createState() => _CustomNumberPickerState();
}

class _CustomNumberPickerState extends State<CustomNumberPicker> {
  late FixedExtentScrollController _mainController;
  late FixedExtentScrollController _decimalController;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _mainController = FixedExtentScrollController(
      initialItem: _currentValue.floor() - widget.minValue.floor(),
    );
    if (widget.showDecimals) {
      _decimalController = FixedExtentScrollController(
        initialItem: ((_currentValue - _currentValue.floor()) * 10).round(),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    if (widget.showDecimals) {
      _decimalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
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
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Scroll Picker
                  SizedBox(
                    width: 100, // Lebar scroll number
                    child: ListWheelScrollView.useDelegate(
                      controller: _mainController,
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: (widget.maxValue - widget.minValue).floor() + 1,
                        builder: (context, index) {
                          final value = widget.minValue.floor() + index;
                          return _buildNumberItem(
                            value.toString(),
                            value == _currentValue.floor(),
                          );
                        },
                      ),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          if (widget.showDecimals) {
                            _currentValue = (widget.minValue + index) +
                                (_decimalController.selectedItem / 10);
                          } else {
                            _currentValue = (widget.minValue + index).toDouble();
                          }
                          widget.onValueChanged(_currentValue);
                        });
                      },
                    ),
                  ),
                  if (widget.showDecimals) ...[
                    const Text(
                      '.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 50, // Lebar scroll desimal
                      child: ListWheelScrollView.useDelegate(
                        controller: _decimalController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 10,
                          builder: (context, index) {
                            return _buildNumberItem(
                              index.toString(),
                              index == (_currentValue - _currentValue.floor()) * 10,
                            );
                          },
                        ),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _currentValue = _currentValue.floor() + (index / 10);
                            widget.onValueChanged(_currentValue);
                          });
                        },
                      ),
                    ),
                  ],
                  // Unit Text
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                    ),
                    child: Container(
                       // Geser lebih jauh
                      alignment: Alignment.center,
                      child: Text(
                        widget.unit,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberItem(String text, bool isSelected) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white38,
          fontSize: isSelected ? 40 : 30,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
