import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/themealdb_service.dart';
import 'recipe_detail_page.dart';
import 'services/firestore_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TheMealDBService _mealDBService = TheMealDBService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Recipe> recipes = [];
  List<Recipe> searchResults = [];
  List<Map<String, String>> popularIngredients = [];
  bool isLoading = false;
  String selectedIngredient = '';
  String sortBy = 'Newest';
  bool _showPopularSection = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes();
    _loadPopularIngredients();
    _scrollController.addListener(_onScroll);
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

  void _saveRecipe(Recipe recipe) async {
    try {
      // Add logic to save the recipe to Firestore or local storage
      await _firestoreService.saveRecipe(recipe);
      // Optional: Show a snackbar or toast to confirm saving
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

  Future<void> _loadInitialRecipes() async {
    setState(() {
      isLoading = true;
    });
    try {
      final recipes = await _mealDBService.getRandomRecipes(number: 10);
      setState(() {
        this.recipes = recipes;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadPopularIngredients() async {
    try {
      final ingredients = await _mealDBService.getPopularIngredients();
      setState(() {
        popularIngredients = ingredients;
      });
    } catch (e) {
      print('Error loading popular ingredients: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && _showPopularSection) {
      setState(() {
        _showPopularSection = false;
      });
    } else if (_scrollController.offset <= 100 && !_showPopularSection) {
      setState(() {
        _showPopularSection = true;
      });
    }
  }

  Future<void> _searchRecipes(String query) async {
    setState(() {
      isLoading = true;
      _isSearching = true;
    });
    try {
      final results = await _mealDBService.searchRecipes(query);
      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      print('Error searching recipes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _searchRecipesByIngredient(String ingredient) async {
    setState(() {
      isLoading = true;
      selectedIngredient = ingredient;
    });
    try {
      // In a real app, you would filter by ingredient
      final recipes = await _mealDBService.getRandomRecipes(number: 10);
      setState(() {
        this.recipes = recipes;
        isLoading = false;
      });
    } catch (e) {
      print('Error searching recipes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '',
            style: TextStyle(
              color: Colors.deepOrange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchRecipes(value);
                } else {
                  setState(() {
                    _isSearching = false;
                  });
                }
              },
            ),
          ),
        ),
        if (!_isSearching) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showPopularSection ? 160 : 0,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Popular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: popularIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = popularIngredients[index];
                        return GestureDetector(
                          onTap: () => _searchRecipesByIngredient(ingredient['name']!),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(ingredient['image']!),
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
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                ingredient['name']!.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recipes you may like',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: sortBy,
                  onSelected: (String value) {
                    setState(() {
                      sortBy = value;
                    });
                  },
                  color: Colors.grey[850],
                  child: Row(
                    children: [
                      Text(
                        sortBy,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Newest',
                      child: Text('Newest', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Popular',
                      child: Text('Popular', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Rating',
                      child: Text('Rating', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
              : _isSearching
                  ? _buildSearchResults()
                  : _buildRecipeGrid(recipes),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Search Results',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _buildRecipeGrid(searchResults),
        ),
        if (searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'You might also like',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (searchResults.isNotEmpty)
          SizedBox(
            height: 200,
            child: _buildRecipeGrid(recipes.take(4).toList(), scrollDirection: Axis.horizontal),
          ),
      ],
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipeList, {Axis scrollDirection = Axis.vertical}) {
    return GridView.builder(
      controller: _scrollController,
      scrollDirection: scrollDirection,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: scrollDirection == Axis.vertical ? 2 : 1,
        childAspectRatio: scrollDirection == Axis.vertical ? 0.8 : 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: recipeList.length,
      itemBuilder: (context, index) {
        final recipe = recipeList[index];
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row with Area Tag and Bookmark
                  Row(
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
                                _saveRecipe(recipe);
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      // Preparation Time and Health Score
                      Row(
                        children: [
                          // Preparation Time
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.preparationTime} min',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 10),

                          // Health Score
                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: _getHealthScoreColor(recipe.healthScore),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                recipe.healthScore.toStringAsFixed(1),
                                style: TextStyle(
                                  color: _getHealthScoreColor(recipe.healthScore),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

