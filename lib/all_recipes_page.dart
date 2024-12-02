import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'recipe_detail_page.dart';
import 'services/firestore_service.dart';

class AllRecipesPage extends StatelessWidget {
  final String title;
  final List<Recipe> recipes;
  final FirestoreService _firestoreService = FirestoreService();

  AllRecipesPage({super.key, required this.title, required this.recipes});

  Color _getHealthScoreColor(double healthScore) {
    if (healthScore < 4.5) {
      return Colors.red;
    } else if (healthScore <= 7.5) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  void _saveRecipe(BuildContext context, Recipe recipe) async {
    try {
      await _firestoreService.saveRecipe(recipe);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe saved: ${recipe.title}')),
      );
    } catch (e) {
      print('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save recipe: ${recipe.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
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
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailPage(recipe: recipe),
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
                  // More Options Icon (Save)
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
                        Positioned(
                          child: Container(
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
                                  _saveRecipe(context, recipe);
                                } else if (value == 'Plan Meal') {}
                              },
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              offset: const Offset(-142.5,45),
                              constraints: const BoxConstraints(
                                minWidth: 175, // Makes popup menu wider
                                maxWidth: 175,
                              ),
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  height: 60, // Makes item taller
                                  value: 'Save Recipe',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.bookmark_border_rounded, size: 22, color: Colors.black87),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Save Recipe',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  height: 60, // Makes item taller
                                  value: 'Plan Meal',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 22, color: Colors.black87),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Plan Meal',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
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
                                    color: _getHealthScoreColor(recipe.healthScore),
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