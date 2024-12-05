import 'package:flutter/material.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  _PlannerPageState createState() => _PlannerPageState();
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: primaryAnimation,
                  curve: Curves.easeOutQuad, // Feel free to customize the curve
                ),
              ),
              child: child,
            );
          },
        );
}

class _PlannerPageState extends State<PlannerPage> {
  List<String> plannedRecipes = []; // Simulasi list planned meal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        backgroundColor: Colors.black, // Warna tema dark
      ),
      backgroundColor: Colors.black, // Warna background dark mode
      body: plannedRecipes.isEmpty
          ? Center(
              child: Text(
                'No planned meals yet',
                style: TextStyle(
                  color: Colors.white, // Teks warna putih agar kontras
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              itemCount: plannedRecipes.length,
              itemBuilder: (context, index) {
                final recipe = plannedRecipes[index];
                return Card(
                  color: Colors.grey[900], // Warna kartu untuk dark mode
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: ListTile(
                    title: Text(
                      recipe,
                      style: const TextStyle(color: Colors.white), // Teks putih
                    ),
                    subtitle: const Text(
                      'Planned meal',
                      style: TextStyle(color: Colors.grey), // Subtitle abu-abu
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          plannedRecipes.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Meal removed from plan'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
