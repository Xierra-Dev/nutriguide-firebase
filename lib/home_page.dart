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
  List<Recipe> feedRecipes = [];
  List<String> viewedRecipeIds = [];
  List<Recipe> viewedRecipes = [];
  bool isLoading = true;
  String? errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadRecipes(),
      _loadViewedRecipes(),
    ]);
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
        errorMessage = 'Failed to load recipes. Please check your internet connection and try again.';
        recommendedRecipes = [];
        popularRecipes = [];
        feedRecipes = [];
      });
    }
  }

  Future<void> _loadViewedRecipes() async {
    try {
      List<String> storedViewedRecipeIds = await _firestoreService.getViewedRecipeIds();

      if (storedViewedRecipeIds.isNotEmpty) {
        List<Recipe> fetchedViewedRecipes = [];
        for (String recipeId in storedViewedRecipeIds) {
          try {
            Recipe recipe = await _mealDBService.getRecipeById(recipeId);
            fetchedViewedRecipes.add(recipe);
          } catch (e) {
            print('Error fetching viewed recipe $recipeId: $e');
          }
        }

        if (mounted) {
          setState(() {
            viewedRecipeIds = storedViewedRecipeIds;
            viewedRecipes = fetchedViewedRecipes;
          });
        }
      }
    } catch (e) {
      print('Error loading viewed recipes: $e');
    }

    // if (viewedRecipeIds.length > 50) {
    //   viewedRecipeIds = viewedRecipeIds.sublist(0, 50);
    //   viewedRecipes = viewedRecipes.sublist(0, 50);
    // }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _loadRecipes(),
      _loadViewedRecipes(),
    ]);

    // Menginformasikan bahwa proses refresh telah selesai
    if (mounted) {
      _refreshIndicatorKey.currentState?.deactivate();
    }
  }


  Future<void> _handleNavigationTap(int index) async {
    if (_currentIndex == index) {
      // Jika pengguna mengetuk ikon saat ini, lakukan refresh halaman
      switch (index) {
        case 0: // Home
          if (index == 0) { // Saved
            _refreshIndicatorKey.currentState?.show();
          }
          await _handleRefresh();
          break;
        case 2: // Planner
          if (index == 2) { // Saved
            _refreshIndicatorKey.currentState?.show();
          }
        // Tambahkan logika untuk me-refresh halaman Planner
          print('Planner page refreshed'); // Ganti dengan metode refresh Planner
          break;
        case 3: // Saved
          if (index == 3) { // Saved
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


  Future<void> _addToViewedRecipes(Recipe recipe) async {
    if (!viewedRecipeIds.contains(recipe.id)) {
      if (mounted) {
        setState(() {
          viewedRecipeIds.insert(0, recipe.id);
          viewedRecipes.insert(0, recipe);

          if (viewedRecipeIds.length > 50) {
            viewedRecipeIds = viewedRecipeIds.sublist(0, 50);
            viewedRecipes = viewedRecipes.sublist(0, 50);
          }
        });
      }

      await Future.wait([
        _firestoreService.saveViewedRecipeIds(viewedRecipeIds),
        _loadViewedRecipes(),
      ]);
    }
  }

  void _navigateToRecipeDetail(Recipe recipe) async {
    await _addToViewedRecipes(recipe);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailPage(recipe: recipe),
        ),
      ).then((_) {
        _loadViewedRecipes();
      });
    }
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
              MaterialPageRoute(builder: (context) => const NotificationsPage()),
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
        return const SearchPage();
      case 2:
        return RefreshIndicator(
          key: _refreshIndicatorKey, // Key untuk animasi refresh
          onRefresh: _handleRefresh, // Sama seperti pull-to-refresh
          color: Colors.deepOrange,
          child: PlannerPage(),
        );;
      case 3:
        return RefreshIndicator(
            key: _refreshIndicatorKey, // Key untuk animasi refresh
            onRefresh: _handleRefresh, // Sama seperti pull-to-refresh
            color: Colors.deepOrange,
        child:  const SavedPage(),
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    } else if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something Went Wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: Text(
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
                    if (viewedRecipes.isNotEmpty) ...[
                      _buildSection('Recently Viewed', viewedRecipes),
                      const SizedBox(height: 24),
                    ],
                    _buildSection('Recommended', recommendedRecipes),
                    const SizedBox(height: 24),
                    _buildSection('Popular', popularRecipes),
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

  Widget _buildSection(String title, List<Recipe> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                    builder: (context) => AllRecipesPage(title: title, recipes: recipes),
                  ),
                ).then((_) {
                  _loadViewedRecipes();
                });
              },
              child: const Text(
                'See All',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return GestureDetector(
                onTap: () => _navigateToRecipeDetail(recipe),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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

            Color healthScoreColor;
            if (recipe.healthScore <= 4.5) {
              healthScoreColor = Colors.red;
            } else if (recipe.healthScore <= 7.5) {
              healthScoreColor = Colors.yellow;
            } else {
              healthScoreColor = Colors.green;
            }

            return GestureDetector(
              onTap: () {
                _navigateToRecipeDetail(recipe);
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
                        children: [
                          const Text(
                            'Health Score: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            recipe.healthScore.toStringAsFixed(1),
                            style: TextStyle(
                              color: healthScoreColor,
                              fontSize: 14.75,
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
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.deepOrange,
      unselectedItemColor: Colors.white,
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap:  _handleNavigationTap,
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
          icon: Icon(Icons.bookmark_border),
          label: 'Saved',
        ),
      ],
    );
  }
}

