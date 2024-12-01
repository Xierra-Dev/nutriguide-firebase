import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'recipe_detail_page.dart';

class AllRecipesPage extends StatelessWidget {
  final String title;
  final List<Recipe> recipes;

  const AllRecipesPage({super.key, required this.title, required this.recipes});

  Color _getHealthScoreColor(double healthScore) {
    if (healthScore < 4.5) {
      return Colors.red;
    } else if (healthScore <= 7.5) {
      return Colors.yellow;
    } else {
      return Colors.green;
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
          childAspectRatio: 1.0, // Mengubah rasio aspek agar lebih sesuai
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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cooking Time
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
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
                    // Health Score with Heart Icon
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
              ),
            ),
          );
        },
      ),
    );
  }
}