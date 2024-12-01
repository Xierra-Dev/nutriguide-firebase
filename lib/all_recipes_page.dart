import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'recipe_detail_page.dart';
import 'services/firestore_service.dart';


class AllRecipesPage extends StatefulWidget {
  final String title;
  final List<Recipe> recipes;
  final Future<List<Recipe>> Function()? onRefresh;

  const AllRecipesPage({
    super.key,
    required this.title,
    required this.recipes,
    this.onRefresh,
  });

  @override
  State<AllRecipesPage> createState() => _AllRecipesPageState();
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
        ) => page,
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
          curve: Curves.easeOutQuad, // You can change the curve for different animation feels
        ),),
        child: child,
      );
    },
  );
}

class _AllRecipesPageState extends State<AllRecipesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late List<Recipe> _recipes;
  List<String> viewedRecipeIds = []; // To track viewed recipe IDs
  List<Recipe> viewedRecipes = [];

  @override
  void initState() {
    super.initState();
    _recipes = widget.recipes;
  }

  Color _getHealthScoreColor(double healthScore) {
    if (healthScore < 4.5) {
      return Colors.red;
    } else if (healthScore <= 7.5) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh != null) {
      final updatedRecipes = await widget.onRefresh!();
      setState(() {
        _recipes = updatedRecipes;
      });
    }
  }

  void _addToViewedRecipes(Recipe recipe) async {
    // Implementasi serupa dengan yang ada di HomePage
    List<String> viewedRecipeIds = await _firestoreService.getViewedRecipeIds();

    if (!viewedRecipeIds.contains(recipe.id)) {
      viewedRecipeIds.insert(0, recipe.id);

      // Batasi hingga 50 resep terakhir yang dilihat
      if (viewedRecipeIds.length > 50) {
        viewedRecipeIds = viewedRecipeIds.sublist(0, 50);
      }

      // Simpan ID resep yang dilihat ke penyimpanan persisten
      await _firestoreService.saveViewedRecipeIds(viewedRecipeIds);
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
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.orange, // Warna animasi
        backgroundColor: Colors.black, // Latar belakang refresh
        child: GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.825,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _recipes.length,
          itemBuilder: (context, index) {
            final recipe = _recipes[index];
            return GestureDetector(
              onTap: () {

                _addToViewedRecipes(recipe);

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
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: Image.network(
                        recipe.image,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey,
                            child: const Icon(Icons.error, color: Colors.white),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                            ),
                            const Spacer(),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Health Score: ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    recipe.healthScore.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: _getHealthScoreColor(recipe.healthScore),
                                      fontSize: 13.75,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}