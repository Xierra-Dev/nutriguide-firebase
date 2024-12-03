import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  _SavedPageState createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Recipe> savedRecipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedRecipes();
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

  Future<void> _loadSavedRecipes() async {
    setState(() {
      isLoading = true;
    });
    try {
      final recipes = await _firestoreService.getSavedRecipes();
      setState(() {
        savedRecipes = recipes;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading saved recipes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleSaveRecipe(Recipe recipe) async {
    try {
      // Remove the recipe from saved recipes
      await _firestoreService.removeFromSavedRecipes(recipe);

      // Update state langsung tanpa loading
      setState(() {
        savedRecipes.removeWhere((r) => r.id == recipe.id);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe: "${recipe.title}" removed from saved'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling save status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ${recipe.title} from saved recipes.\nError: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 5, 0, 8),
              child: Text(
                'Saved Recipes',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                  : savedRecipes.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadSavedRecipes,
                color: Colors.deepOrange,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: savedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = savedRecipes[index];
                    return _buildRecipeCard(recipe);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved recipes yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadSavedRecipes,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Refresh', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        ).then((_) => _loadSavedRecipes());
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(recipe.image),
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
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recipe.area ?? 'International',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.preparationTime} min',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const Spacer(),
                      Icon(Icons.favorite, color: _getHealthScoreColor(recipe.healthScore), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        recipe.healthScore.toStringAsFixed(1),
                        style: TextStyle(color: _getHealthScoreColor(recipe.healthScore), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8.75,
            right: 10,
            child: Container(
              width: 32.5,
              height: 32.5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.bookmark,
                  color: Colors.deepOrange,
                  size: 17.5,
                ),
                onPressed: () => _toggleSaveRecipe(recipe),
              ),
            ),
          ),
        ],
      ),
    );
  }
}