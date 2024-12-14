import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/nutrition_goals.dart';
import 'package:intl/intl.dart';

class NutritionTracker extends StatefulWidget {
  final NutritionGoals nutritionGoals;

  const NutritionTracker({
    Key? key,
    required this.nutritionGoals,
  }) : super(key: key);

  @override
  _NutritionTrackerState createState() => _NutritionTrackerState();
}

class _NutritionTrackerState extends State<NutritionTracker> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = true;
  Map<String, double> todayNutrition = {
    'calories': 0,
    'carbs': 0,
    'fiber': 0,
    'protein': 0,
    'fat': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTodayNutrition();
  }

  Future<void> _loadTodayNutrition() async {
    setState(() => isLoading = true);
    try {
      final data = await _firestoreService.getTodayNutrition();
      setState(() {
        todayNutrition = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading nutrition: $e');
      setState(() => isLoading = false);
    }
  }

  double getResponsiveSize(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  Widget _buildNutrientProgress(String label, String nutrient, Color color) {
    final current = todayNutrition[nutrient] ?? 0;
    final goal = switch (nutrient) {
      'calories' => widget.nutritionGoals.calories,
      'carbs' => widget.nutritionGoals.carbs,
      'fiber' => widget.nutritionGoals.fiber,
      'protein' => widget.nutritionGoals.protein,
      'fat' => widget.nutritionGoals.fat,
      _ => 0.0,
    };

    final progress = (current / goal).clamp(0.0, 1.0);
    final unit = nutrient == 'calories' ? 'kcal' : 'g';
    final isExceeded = current > goal;

    return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final labelSize = maxWidth * 0.04;  // 4% of container width
          final valueSize = maxWidth * 0.035; // 3.5% of container width
          final warningSize = maxWidth * 0.03; // 3% of container width

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      if (isExceeded)
                        Padding(
                          padding: EdgeInsets.only(right: maxWidth * 0.02),
                          child: Icon(
                            Icons.warning_rounded,
                            color: Colors.red,
                            size: labelSize,
                          ),
                        ),
                      Text(
                        '${current.toStringAsFixed(1)}/$goal$unit',
                        style: TextStyle(
                          color: isExceeded ? Colors.red : Colors.grey[400],
                          fontSize: valueSize,
                          fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: maxWidth * 0.02),
              Stack(
                children: [
                  Container(
                    height: maxWidth * 0.02,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(maxWidth * 0.01),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: maxWidth * 0.02,
                      decoration: BoxDecoration(
                        color: isExceeded ? Colors.red : color,
                        borderRadius: BorderRadius.circular(maxWidth * 0.01),
                        boxShadow: [
                          BoxShadow(
                            color: (isExceeded ? Colors.red : color).withOpacity(0.5),
                            blurRadius: maxWidth * 0.01,
                            offset: Offset(0, maxWidth * 0.005),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExceeded)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(maxWidth * 0.01),
                          border: Border.all(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isExceeded)
                Padding(
                  padding: EdgeInsets.only(top: maxWidth * 0.01),
                  child: Text(
                    'Exceeded by ${(current - goal).toStringAsFixed(1)}$unit',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: warningSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasExceededLimits = false;
    if (!isLoading) {
      hasExceededLimits = (todayNutrition['calories'] ?? 0) > widget.nutritionGoals.calories ||
          (todayNutrition['carbs'] ?? 0) > widget.nutritionGoals.carbs ||
          (todayNutrition['fiber'] ?? 0) > widget.nutritionGoals.fiber ||
          (todayNutrition['protein'] ?? 0) > widget.nutritionGoals.protein ||
          (todayNutrition['fat'] ?? 0) > widget.nutritionGoals.fat;
    }

    return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final titleSize = maxWidth * 0.05;    // 5% of container width
          final dateSize = maxWidth * 0.035;    // 3.5% of container width
          final warningSize = maxWidth * 0.03;  // 3% of container width

          return Container(
            padding: EdgeInsets.all(maxWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(maxWidth * 0.04),
              border: hasExceededLimits
                  ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: hasExceededLimits
                      ? Colors.red.withOpacity(0.2)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: maxWidth * 0.02,
                  offset: Offset(0, maxWidth * 0.01),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Nutrition",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (hasExceededLimits)
                          Padding(
                            padding: EdgeInsets.only(right: maxWidth * 0.02),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: maxWidth * 0.02,
                                vertical: maxWidth * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(maxWidth * 0.03),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_rounded,
                                      color: Colors.red,
                                      size: warningSize * 1.3),
                                  SizedBox(width: maxWidth * 0.01),
                                  Text(
                                    'Limit Exceeded',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: warningSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.refresh,
                              color: Colors.white,
                              size: titleSize),
                          onPressed: _loadTodayNutrition,
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: dateSize,
                  ),
                ),
                SizedBox(height: maxWidth * 0.06),
                if (isLoading)
                  Center(
                    child: SizedBox(
                      width: maxWidth * 0.1,
                      height: maxWidth * 0.1,
                      child: CircularProgressIndicator(
                        color: Colors.deepOrange,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildNutrientProgress('Calories', 'calories', Colors.blue),
                      SizedBox(height: maxWidth * 0.04),
                      _buildNutrientProgress('Carbs', 'carbs', Colors.orange),
                      SizedBox(height: maxWidth * 0.04),
                      _buildNutrientProgress('Fiber', 'fiber', Colors.green),
                      SizedBox(height: maxWidth * 0.04),
                      _buildNutrientProgress('Protein', 'protein', Colors.pink),
                      SizedBox(height: maxWidth * 0.04),
                      _buildNutrientProgress('Fat', 'fat', Colors.purple),
                    ],
                  ),
                if (hasExceededLimits)
                  Padding(
                    padding: EdgeInsets.only(top: maxWidth * 0.04),
                    child: Container(
                      padding: EdgeInsets.all(maxWidth * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(maxWidth * 0.02),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.red,
                              size: warningSize * 1.3),
                          SizedBox(width: maxWidth * 0.02),
                          Expanded(
                            child: Text(
                              'You have exceeded your daily nutrition limits. Consider adjusting your meal plan.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: warningSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
    );
  }
}