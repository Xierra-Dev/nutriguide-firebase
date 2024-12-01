import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/themealdb_service.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';
import 'all_recipes_page.dart';
import 'search_page.dart';
import 'saved_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'add_recipe_page.dart';
import 'planner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TheMealDBService _mealDBService = TheMealDBService();
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<Recipe> recommendedRecipes = [];
  List<Recipe> popularRecipes = [];
  List<Recipe> recentlyViewedRecipes = [];
  List<Recipe> feedRecipes = [];
  bool isLoading = true;
  bool _isFirstTimeLoading = true;
  String? errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _loadRecentlyViewedRecipes();
  }

  Color _getHealthScoreColor(double score) {
    if (score <= 4.5) {
      return Colors.red;
    } else if (score <= 7.5) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Future<void> _loadRecipes() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final futures = await Future.wait([
        _mealDBService.getRandomRecipes(number: 20),
        _mealDBService.getRecipesByCategory('Seafood'),
        _mealDBService.getRandomRecipes(number: 10),
      ]);

      setState(() {
        recommendedRecipes = futures[0];
        popularRecipes = futures[1];
        feedRecipes = futures[2];
        isLoading = false;
      });

      print('Loaded ${recommendedRecipes.length} recommended recipes');
      print('Loaded ${popularRecipes.length} popular recipes');
      print('Loaded ${feedRecipes.length} feed recipes');
    } catch (e) {
      print('Error in _loadRecipes: $e');
      setState(() {
        isLoading = false;
        errorMessage =
            'Failed to load recipes. Please check your internet connection and try again.';
        recommendedRecipes = [];
        popularRecipes = [];
        feedRecipes = [];
      });
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

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        // Only set isLoading to true for first-time loading
        if (_isFirstTimeLoading) {
          isLoading = true;
        }
        errorMessage = null;
      });

      final futures = await Future.wait([
        _mealDBService.getRandomRecipes(number: 20),
        _mealDBService.getRecipesByCategory('Seafood'),
        _mealDBService.getRandomRecipes(number: 10),
      ]);

      setState(() {
        recommendedRecipes = futures[0];
        popularRecipes = futures[1];
        feedRecipes = futures[2];

        // Reset first-time loading
        isLoading = false;
        _isFirstTimeLoading = false;
      });

      print('Loaded ${recommendedRecipes.length} recommended recipes');
      print('Loaded ${popularRecipes.length} popular recipes');
      print('Loaded ${feedRecipes.length} feed recipes');
    } catch (e) {
      print('Error in _loadRecipes: $e');
      setState(() {
        // Only set isLoading to false for first-time loading
        if (_isFirstTimeLoading) {
          isLoading = false;
        }

        errorMessage =
            'Failed to load recipes. Please check your internet connection and try again.';
        recommendedRecipes = [];
        popularRecipes = [];
        feedRecipes = [];
      });
    }
  }

  Future<void> _handleRefresh() async {
    // Reset error message during refresh
    setState(() {
      errorMessage = null;
    });

    await Future.wait([
      _loadRecipes(),
      _loadRecentlyViewedRecipes(),
    ]);

    if (mounted) {
      _refreshIndicatorKey.currentState?.deactivate();
    }
  }

  Future<void> _handleNavigationTap(int index) async {
    if (_currentIndex == index) {
      // Jika pengguna mengetuk ikon saat ini, lakukan refresh halaman
      switch (index) {
        case 0: // Home
          if (index == 0) {
            // Saved
            _refreshIndicatorKey.currentState?.show();
          }
          await _handleRefresh();
          break;
        case 2: // Planner
          if (index == 2) {
            // Saved
            _refreshIndicatorKey.currentState?.show();
          }
          // Tambahkan logika untuk me-refresh halaman Planner
          print(
              'Planner page refreshed'); // Ganti dengan metode refresh Planner
          break;
        case 3: // Saved
          if (index == 3) {
            // Saved
            _refreshIndicatorKey.currentState?.show();
          }
          // Tambahkan logika untuk me-refresh halaman Saved
          print('Saved page refreshed'); // Ganti dengan metode refresh Saved
          break;
      }
    } else {
      // Jika pengguna mengetuk ikon berbeda, navigasikan ke indeks baru
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _loadRecentlyViewedRecipes() async {
    try {
      final recipes = await _firestoreService.getRecentlyViewedRecipes();
      setState(() {
        recentlyViewedRecipes = recipes;
      });
    } catch (e) {
      print('Error loading recently viewed recipes: $e');
    }
  }

  void _viewRecipe(Recipe recipe) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(recipe: recipe),
      ),
    );
    // Reload recently viewed recipes after returning from RecipeDetailPage
    _loadRecentlyViewedRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _currentIndex == 1 ? null : _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecipePage()),
          );
        },
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar? _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'For you',
            style: TextStyle(
              color: Colors.deepOrange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            height: 2,
            width: 60,
            color: Colors.deepOrange,
            margin: const EdgeInsets.only(top: 4),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationsPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return RefreshIndicator(
          key: _refreshIndicatorKey, // Key untuk animasi refresh
          onRefresh: _handleRefresh, // Sama seperti pull-to-refresh
          color: Colors.deepOrange,
          child: _buildHomeContent(),
        );
      case 1:
        return RefreshIndicator(
          key: _refreshIndicatorKey, // Key untuk animasi refresh
          onRefresh: _handleRefresh, // Sama seperti pull-to-refresh
          color: Colors.deepOrange,
          child: SearchPage(),
        );
      case 2:
        return RefreshIndicator(
          key: _refreshIndicatorKey, // Key untuk animasi refresh
          onRefresh: _handleRefresh, // Sama seperti pull-to-refresh
          color: Colors.deepOrange,
          child: PlannerPage(),
        );
      case 3:
        return RefreshIndicator(
          key: _refreshIndicatorKey, // Key untuk animasi refresh
          onRefresh: _handleRefresh, // Sama seperti pull-to-refresh
          color: Colors.deepOrange,
          child: const SavedPage(),
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildRecipeSection(String title, List<Recipe> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllRecipesPage(
                        title: title,
                        recipes: recipes,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'See All',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return GestureDetector(
                onTap: () => _viewRecipe(recipe),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(left: 16, bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(recipe.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                const Icon(Icons.timer,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe.preparationTime} min',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                const Spacer(),
                                Icon(Icons.favorite,
                                    color: _getHealthScoreColor(
                                        recipe.healthScore),
                                    size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  recipe.healthScore.toStringAsFixed(1),
                                  style: TextStyle(
                                      color: _getHealthScoreColor(
                                          recipe.healthScore),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: (String value) {
                            if (value == 'Save') {
                              _saveRecipe(recipe);
                            } else if (value == 'Plan') {}
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'Save',
                              child: Text('Save'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Plan',
                              child: Text('Plan'),
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
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    // If it's the first-time loading, show the circular progress indicator
    if (_isFirstTimeLoading && isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange));
    }
    // If there's an error message (which can happen anytime after first load)
    else if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something Went Wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.deepOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recentlyViewedRecipes.isNotEmpty) ...[
                      _buildRecipeSection(
                          'Recently Viewed', recentlyViewedRecipes),
                      const SizedBox(height: 24),
                    ],
                    _buildRecipeSection('Recommended', recommendedRecipes),
                    const SizedBox(height: 24),
                    _buildRecipeSection('Popular', popularRecipes),
                  ],
                ),
              ),
              _buildRecipeFeed(),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildRecipeFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recipe Feed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: feedRecipes.length,
          itemBuilder: (context, index) {
            final recipe = feedRecipes[index];
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
                height: 250,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(recipe.image),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Health Score: ${recipe.healthScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color:
                                      _getHealthScoreColor(recipe.healthScore),
                                  fontSize: 14,
                                ),
                              ),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        onSelected: (String value) {
                          if (value == 'Save') {
                            _saveRecipe(recipe);
                          } else if (value == 'Plan') {}
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'Save',
                            child: Text('Save'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Plan',
                            child: Text('Plan'),
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
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) async {
        await _handleNavigationTap(index);
      },
      backgroundColor: Colors.deepOrange,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Planner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Saved',
        ),
      ],
    );
  }
}
