import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'recipe_detail_page.dart';
import 'services/firestore_service.dart';
import 'home_page.dart';

class AllRecipesPage extends StatefulWidget {
  final String title;
  final List<Recipe> recipes;

  const AllRecipesPage({super.key, required this.title, required this.recipes});

  @override
  _AllRecipesPageState createState() => _AllRecipesPageState();
}

class SlideLeftRoute extends PageRouteBuilder {
  final Widget page;

  SlideLeftRoute({required this.page})
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
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
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
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
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
          begin: const Offset(0.0, 1.0),  // Start from bottom
          end: Offset.zero,  // End at the center
        ).animate(CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.easeOutQuad,
        )),
        child: child,
      );
    },
  );
}

class _AllRecipesPageState extends State<AllRecipesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isSaved = false;
  bool isLoading = false;
  Map<String, bool> savedStatus = {};
  Map<String, bool> plannedStatus = {};

  @override
  void initState() {
    super.initState();
    // Inisialisasi status untuk setiap resep
    for (var recipe in widget.recipes) {
      _checkIfSaved(recipe);
    }
  }

  Color _getHealthScoreColor(double healthScore) {
    if (healthScore < 6) {
      return Colors.red;
    } else if (healthScore <= 7.5) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Future<void> _checkIfSaved(Recipe recipe) async {
    final saved = await _firestoreService.isRecipeSaved(recipe.id);
    setState(() {
      savedStatus[recipe.id] = saved;
    });
  }

  Future<void> _toggleSave(Recipe recipe) async {
    setState(() {
      isLoading = true;
    });
    try {
      if (savedStatus[recipe.id] == true) {
        await _firestoreService.unsaveRecipe(recipe.id);
      } else {
        await _firestoreService.saveRecipe(recipe);
      }
      setState(() {
        savedStatus[recipe.id] = !(savedStatus[recipe.id] ?? false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedStatus[recipe.id] == true
                ? 'Recipe saved: ${recipe.title}'
                : 'Recipe: "${recipe.title}" removed from saved',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving recipe'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        // Add automatic back navigation with SlideRightRoute
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(SlideRightRoute);
          },
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: widget.recipes.length,
        itemBuilder: (context, index) {
          final recipe = widget.recipes[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                SlideUpRoute(
                  page: RecipeDetailPage(recipe: recipe),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
                image: DecorationImage(
                  image: NetworkImage(recipe.image),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            recipe.area ?? 'International',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          width: 32.5,
                          height: 32.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 24,
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            onSelected: (String value) {
                              if (value == 'Save Recipe') {
                                _toggleSave(recipe);
                              } else if (value == 'Plan Meal') {
                              }
                            },
                            color: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            offset: const Offset(0, 45),
                            constraints: const BoxConstraints(
                              minWidth: 175,
                              maxWidth: 175,
                            ),
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                height: 60,
                                value: 'Save Recipe',
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.bookmark_border_rounded,
                                        size: 22,
                                        color: savedStatus[recipe.id] == true
                                            ? Colors.deepOrange
                                            : Colors.black87,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        savedStatus[recipe.id] == true
                                            ? 'Saved'
                                            : 'Save Recipe',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: savedStatus[recipe.id] == true
                                              ? Colors.deepOrange
                                              : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              PopupMenuItem<String>(
                                height: 60,
                                value: 'Plan Meal',
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 22,
                                        color: plannedStatus[recipe.id] == true
                                            ? Colors.deepOrange
                                            : Colors.black87,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        plannedStatus[recipe.id] == true
                                            ? 'Planned'
                                            : 'Plan Meal',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: plannedStatus[recipe.id] == true
                                              ? Colors.deepOrange
                                              : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Recipe Content
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        // Recipe Title
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Bottom Row with Preparation Time and Health Score
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Preparation Time (Left)
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe.preparationTime} min',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            // Health Score (Right)
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: _getHealthScoreColor(recipe.healthScore),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  recipe.healthScore.toStringAsFixed(1),
                                  style: TextStyle(
                                    color:
                                    _getHealthScoreColor(recipe.healthScore),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}