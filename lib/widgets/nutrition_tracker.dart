import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import 'nutrition_goals_dialog.dart';
import '../models/nutrition_goals.dart';
class NutritionTracker extends StatefulWidget {
  final NutritionGoals nutritionGoals;

  const NutritionTracker({
    Key? key,
    required this.nutritionGoals,
  }) : super(key: key);

  @override
  _NutritionTrackerState createState() => _NutritionTrackerState();
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  
  DashedLinePainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 5, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _NutritionTrackerState extends State<NutritionTracker> {
  final FirestoreService _firestoreService = FirestoreService();
  int selectedWeek = 1;
  String selectedNutrient = 'carbs';
  Map<String, List<double>> weeklyNutrition = {};
  bool isLoading = true;
  final Map<String, Color> nutrientColors = {
    'calories': Colors.blue,
    'carbs': Colors.orange,
    'fiber': Colors.green,
    'protein': Colors.pink,
    'fat': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _loadWeeklyNutrition();
  }

  Future<void> _loadWeeklyNutrition() async {
    setState(() => isLoading = true);
    final data = await _firestoreService.getWeeklyNutrition(selectedWeek);
    setState(() {
      weeklyNutrition = data;
      isLoading = false;
    });
  }

  double _getMaxValue() {
    if (weeklyNutrition.isEmpty || weeklyNutrition[selectedNutrient] == null) {
      return 0;
    }
    
    // Use nutrition goals as maximum values
    switch (selectedNutrient) {
      case 'calories':
        return widget.nutritionGoals.calories;
      case 'carbs':
        return widget.nutritionGoals.carbs;
      case 'fiber':
        return widget.nutritionGoals.fiber;
      case 'protein':
        return widget.nutritionGoals.protein;
      case 'fat':
        return widget.nutritionGoals.fat;
      default:
        return 0;
    }
  }

  int _getCurrentDayIndex() {
    // Mengambil hari saat ini dalam bentuk indeks (0 untuk Minggu, 1 untuk Senin, dst.)
    return DateTime.now().weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 25,
        horizontal: 17.5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: Text('Select Week', style: TextStyle(color: Colors.white)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          4,
                          (index) => ListTile(
                            title: Text(
                              'Week ${index + 1}',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              setState(() => selectedWeek = index + 1);
                              Navigator.pop(context);
                              _loadWeeklyNutrition();
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Week $selectedWeek',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: nutrientColors[selectedNutrient],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getMaxValue().toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoading)
            Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          else
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // Garis putus-putus horizontal
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: CustomPaint(
                        painter: DashedLinePainter(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        size: const Size(double.infinity, 1),
                      ),
                    ),
                  ),
                  // Bar Chart
                  BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxValue(),
                      minY: 0,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: selectedNutrient == 'carbs' && value.toInt() == _getCurrentDayIndex()
                                        ? nutrientColors[selectedNutrient] 
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        7,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: weeklyNutrition[selectedNutrient]?[index] ?? 0,
                              color: selectedNutrient == 'carbs' && index == _getCurrentDayIndex()
                                  ? nutrientColors[selectedNutrient]
                                  : Colors.grey[800],
                              width: 30,
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNutrientSelector('Cal', 'calories', Colors.blue),
              _buildNutrientSelector('Carbs', 'carbs', Colors.orange),
              _buildNutrientSelector('Fiber', 'fiber', Colors.green),
              _buildNutrientSelector('Protein', 'protein', Colors.pink),
              _buildNutrientSelector('Fat', 'fat', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientSelector(String label, String value, Color color) {
    final isSelected = selectedNutrient == value;
    return GestureDetector(
      onTap: () {
        setState(() => selectedNutrient = value);
      },
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}