import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/planned_recipe.dart';
import 'models/recipe.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  _PlannerPageState createState() => _PlannerPageState();
}

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
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
          begin: const Offset(0.0, 1.0), // Start from bottom
          end: Offset.zero, // End at the center
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
}

class _PlannerPageState extends State<PlannerPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, List<PlannedMeal>> weeklyMeals = {};
  bool isLoading = true;
  Map<String, bool> madeStatus = {};

  // Track the current week
  DateTime currentSunday = DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));

  @override
  void initState() {
    super.initState();
    _loadPlannedMeals();
  }

  void _viewRecipe(Recipe recipe) async {
    await _firestoreService.addToRecentlyViewed(recipe);
    if (mounted) {
      await Navigator.push(
        context,
        SlideUpRoute(page: RecipeDetailPage(recipe: recipe)),
      );
    }
  }

  Future<void> _loadPlannedMeals() async {
    setState(() => isLoading = true);
    try {
      final meals = await _firestoreService.getPlannedMeals();
      setState(() {
        weeklyMeals = meals;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading planned meals: $e')),
      );
    }
  }

  void _changeWeek(int delta) {
    setState(() {
      currentSunday = currentSunday.add(Duration(days: delta * 7));
    });
  }

  Future<void> _toggleMade(PlannedMeal plannedMeal) async {
    try {
      // Generate a unique identifier for this specific planned meal
      final String mealKey = '${plannedMeal.recipe.id}_${plannedMeal.mealType}_${plannedMeal.dateKey}';

      final bool currentStatus = madeStatus[mealKey] ?? false;

      if (madeStatus[mealKey] == true) {
        // Remove the specific planned meal from made recipes
        await _firestoreService.removeMadeRecipe(mealKey);
      } else {
        // Add this specific planned meal as a made recipe
        await _firestoreService.madeRecipe(plannedMeal.recipe, additionalKey: mealKey);
      }

      setState(() {
        madeStatus[mealKey] = !currentStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                  madeStatus[mealKey] == true
                      ? Icons.bookmark_added
                      : Icons.delete_rounded,
                  color: madeStatus[mealKey] == true
                      ? Colors.white
                      : Colors.red
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  madeStatus[mealKey] == true
                      ? 'Recipe: "${plannedMeal.recipe.title}" made'
                      : 'Recipe: "${plannedMeal.recipe.title}" unmade',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error made recipe: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 5),
              child: Text(
                'Planned Recipes',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Week Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_left_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: () => _changeWeek(-1),
                  ),
                  Text(
                    '${DateFormat('MMM d').format(currentSunday)} - '
                        '${DateFormat('MMM d').format(currentSunday.add(Duration(days: 6)))}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_right_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: () => _changeWeek(1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange,))
                  : _buildWeekMeals(currentSunday),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekMeals(DateTime sunday) {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final day = DateTime(
          sunday.year,
          sunday.month,
          sunday.day + index,
        );
        final dateKey = DateFormat('yyyy-MM-dd').format(day);
        final dayName = DateFormat('EEEE').format(day);
        final dateStr = DateFormat('d MMM').format(day);

        final meals = weeklyMeals[dateKey] ?? [];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Row(
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
                onTap: () => _showDayMeals(context, '$dayName, $dateStr', meals),
              ),
              if (meals.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: meals.length,
                    itemBuilder: (context, mealIndex) {
                      final meal = meals[mealIndex];

                      // Generate a unique key for this specific planned meal
                      final mealKey = '${meal.recipe.id}_${meal.mealType}_${meal.dateKey}';
                      // Inside the horizontal ListView.builder
                      return GestureDetector(
                        onTap: () => _viewRecipe(meal.recipe),
                        child: Stack(
                          children: [
                            Container(
                              width: 250,
                              margin: const EdgeInsets.only(right: 16, bottom: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: NetworkImage(meal.recipe.image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      meal.recipe.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${meal.recipe.preparationTime} min',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          meal.mealType,
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Simplified check circle icon
                            Positioned(
                              top: -3,
                              right: 16,
                              child: IconButton(
                                iconSize: 30,
                                icon: Icon(
                                  Icons.check_circle,
                                  color: madeStatus[mealKey] ?? false
                                      ? Colors.green
                                      : Colors.white,
                                ),
                                onPressed: () => _toggleMade(meal),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'No meals planned for $dayName, $dateStr',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePlannedMeal(PlannedMeal meal, String dayName) async {
    try {
      await _firestoreService.deletePlannedMeal(meal);
      // Reload meals after deletion
      await _loadPlannedMeals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 10),
                Text('Recipe: "${meal.recipe.title}" removed from $dayName'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text('Error removing meal: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePlannedMealByDay(String dayName) async {
    try {
      // Parse the dayName back to a date
      // Example dayName format: "Monday, 25 Dec"
      final parts = dayName.split(', ');

      // Get the date for the specified day from currentSunday
      final targetDate = currentSunday.add(
        Duration(
          days: [
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday'
          ].indexOf(parts[0]),
        ),
      );

      // Format the date to match the dateKey format used in weeklyMeals
      final dateKey = DateFormat('yyyy-MM-dd').format(targetDate);

      // Get all meals for that day
      final mealsForDay = weeklyMeals[dateKey] ?? [];

      // Delete each meal
      for (final meal in mealsForDay) {
        await _firestoreService.deletePlannedMeal(meal);
      }

      // Reload the meals to update the UI
      await _loadPlannedMeals();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 10),
                Text('All meals for $dayName have been deleted'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text('Error removing meal: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDayMeals(BuildContext context, String dayName, List<PlannedMeal> meals) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meals for $dayName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // List of meals
              Expanded(
                child: meals.isEmpty
                    ? Center(
                  child: Text(
                    'No meals planned for $dayName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            SlideUpRoute(
                              page: RecipeDetailPage(
                                recipe: meal.recipe,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              meal.recipe.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  meal.recipe.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  meal.mealType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                Icons.timer,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${meal.recipe.preparationTime} min',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _deletePlannedMeal(meal, dayName);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Fixed Delete All Meals button
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: meals.isNotEmpty
                        ? () {
                      // Show confirmation dialog before deleting all meals
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return Dialog(
                            backgroundColor: Colors.transparent, // Membuat latar dialog transparan
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.25,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E), // Warna latar belakang gelap
                                borderRadius: BorderRadius.circular(28), // Sudut yang lebih bulat
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 9,),
                                  const Text(
                                    'Delete All Meals',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 21.5),
                                  const Text(
                                    'Are you sure you want to delete all meals\nfor this day?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 37),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Cancel Button
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: EdgeInsets.symmetric(vertical: 12),
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
                                      ),
                                      const SizedBox(width: 12),
                                      // Delete Button
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                            Navigator.of(context).pop();
                                            _deletePlannedMealByDay(dayName);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                          ),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Delete All Meals'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}