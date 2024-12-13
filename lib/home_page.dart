import 'package:flutter/material.dart';
import 'package:nutriguide/assistant_page.dart';
import 'models/recipe.dart';
import 'services/themealdb_service.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';
import 'all_recipes_page.dart';
import 'search_page.dart';
import 'saved_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'planner_page.dart';
import 'package:intl/intl.dart';
import 'services/cache_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
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

class _HomePageState extends State<HomePage> {
  final TheMealDBService _mealDBService = TheMealDBService();
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final CacheService _cacheService = CacheService();
  Map<String, bool> savedStatus = {};
  Map<String, bool> plannedStatus = {};
  List<Recipe> recommendedRecipes = [];
  List<Recipe> popularRecipes = [];
  List<Recipe> recentlyViewedRecipes = [];
  List<Recipe> feedRecipes = [];
  bool isLoading = true;
  bool _isRefreshing = false;
  final bool _isFirstTimeLoading = true;
  String? errorMessage;
  int _currentIndex = 0;

  DateTime _selectedDate = DateTime.now();
  String _selectedMeal = 'Dinner';
  List<bool> _daysSelected = List.generate(7, (index) => false);

  @override
  void initState() {
    super.initState();
    _loadRecipes().then((_) {
      // After recipes are loaded, check saved status for each recipe
      for (var recipe in recommendedRecipes) {
        _checkIfSaved(recipe);
        _checkIfPlanned(recipe);
      }
      for (var recipe in popularRecipes) {
        _checkIfSaved(recipe);
        _checkIfPlanned(recipe);
      }
      for (var recipe in feedRecipes) {
        _checkIfSaved(recipe);
        _checkIfPlanned(recipe);
      }
    });
    _loadRecentlyViewedRecipes();
  }

  Color _getHealthScoreColor(double score) {
    if (score < 6) {
      return Colors.red;
    } else if (score <= 7.5) {
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

  Future<void> _checkIfPlanned(Recipe recipe) async {
    final planned = await _firestoreService.isRecipePlanned(recipe.id);
    setState(() {
      plannedStatus[recipe.id] = planned;
    });
  }

  Future<void> _toggleSave(Recipe recipe) async {
    try {
      final bool currentStatus = savedStatus[recipe.id] ?? false;

      if (savedStatus[recipe.id] == true) {
        await _firestoreService.unsaveRecipe(recipe.id);
      } else {
        await _firestoreService.saveRecipe(recipe);
      }
      setState(() {
        savedStatus[recipe.id] = !currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                  savedStatus[recipe.id] == true
                      ? Icons.bookmark_added
                      : Icons.delete_rounded,
                  color: savedStatus[recipe.id] == true
                      ? Colors.deepOrange
                      : Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  savedStatus[recipe.id] == true
                      ? 'Recipe: "${recipe.title}" saved'
                      : 'Recipe: "${recipe.title}" removed from saved',
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
                child: Text('Error plan recipe: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePlan(Recipe recipe) async {
    try {
      // Show the planning dialog without changing the planned status yet
      _showPlannedDialog(recipe);
    } catch (e) {
      // Handle error and show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Error planning recipe: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMealSelectionDialog(
      BuildContext context, StateSetter setDialogState, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter mealSetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Meal Type',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width *
                          0.05, // Adjust font size based on screen width
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Meal type selection
                  ListView(
                    shrinkWrap: true,
                    children: [
                      'Breakfast',
                      'Lunch',
                      'Dinner',
                      'Supper',
                      'Snacks'
                    ].map((String mealType) {
                      return ListTile(
                        title: Text(
                          mealType,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width *
                                0.05, // Adjust font size based on screen width
                          ),
                        ),
                        onTap: () {
                          // Update the selected meal in the parent dialog
                          setDialogState(() {
                            _selectedMeal = mealType;
                          });
                          // Close both dialogs
                          Navigator.of(context)
                              .pop(); // Close meal selection dialog
                          Navigator.of(context).pop(); // Close parent dialog

                          // Reopen the parent dialog with selected meal
                          _showPlannedDialog(recipe);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Cancel button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPlannedDialog(Recipe recipe) {
    // Reset selected days
    _daysSelected = List.generate(7, (index) => false);

    // Get the start of week (Sunday)
    DateTime now = DateTime.now();
    _selectedDate = now.subtract(Duration(days: now.weekday % 7));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // Background for dark mode
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with week navigation
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double textSize = constraints.maxWidth * 0.05;
                      return Text(
                        'Choose Day',
                        style: TextStyle(
                          fontSize: textSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Move to the previous week
                          setDialogState(() {
                            _selectedDate =
                                _selectedDate.subtract(const Duration(days: 7));
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_left_rounded,
                          size: 40,
                        ),
                        color: Colors.white,
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double textSize = constraints.maxWidth * 0.05;
                          return Text(
                            '${DateFormat('MMM dd').format(_selectedDate)} - '
                            '${DateFormat('MMM dd').format(_selectedDate.add(const Duration(days: 6)))}',
                            style: TextStyle(
                              fontSize: textSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          // Move to the next week
                          setDialogState(() {
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 7));
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_right_rounded,
                          size: 40,
                        ),
                        color: Colors.white,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 60,
                    child: Center(
                      child: InkWell(
                        onTap: () {
                          // Open meal selection dialog
                          _showMealSelectionDialog(
                              context, setDialogState, recipe);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  double textSize = constraints.maxWidth * 0.05;
                                  return Text(
                                    _selectedMeal.isEmpty
                                        ? 'Select Meal'
                                        : _selectedMeal,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: textSize,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Day selection using ChoiceChip
                  Wrap(
                    spacing: 8,
                    children: [
                      for (int i = 0; i < 7; i++)
                        ChoiceChip(
                          label: LayoutBuilder(
                            builder: (context, constraints) {
                              double textSize = constraints.maxWidth * 0.05;
                              return Text(
                                DateFormat('EEE').format(
                                  _selectedDate.add(Duration(
                                      days: i - _selectedDate.weekday % 7)),
                                ), // Display day starting from Sunday
                                style: TextStyle(
                                  fontSize: textSize,
                                  color: _daysSelected[i]
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              );
                            },
                          ),
                          selected: _daysSelected[i],
                          onSelected: (bool selected) {
                            setDialogState(() {
                              _daysSelected[i] = selected;
                            });
                          },
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.grey[800],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedMeal.isEmpty ||
                              !_daysSelected.contains(true)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please select at least one day and a meal type!'),
                              ),
                            );
                            return;
                          }
                          _saveSelectedPlan(recipe); // Pass the recipe
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double textSize = constraints.maxWidth * 0.04;
                            return Text(
                              'Done',
                              style: TextStyle(
                                fontSize: textSize,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Fungsi untuk menyimpan pilihan (sesuaikan dengan logika aplikasi Anda)
  void _saveSelectedPlan(Recipe recipe) async {
    try {
      List<DateTime> selectedDates = [];
      List<DateTime> successfullyPlannedDates =
          []; // Untuk menyimpan tanggal yang berhasil direncanakan

      for (int i = 0; i < _daysSelected.length; i++) {
        if (_daysSelected[i]) {
          // Normalize the date
          DateTime selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day + i,
          );
          print('Selected date: $selectedDate');
          selectedDates.add(selectedDate);
        }
      }

      for (DateTime date in selectedDates) {
        // Periksa apakah rencana dengan tanggal ini sudah ada
        bool exists = await _firestoreService.checkIfPlanExists(
          recipe.id,
          _selectedMeal,
          date,
        );

        if (exists) {
          print('Duplicate plan detected for date: $date');
          continue; // Lewati tanggal yang sudah direncanakan
        }

        // Simpan rencana baru
        print('Saving recipe for date: $date');
        await _firestoreService.addPlannedRecipe(
          recipe,
          _selectedMeal,
          date,
        );

        successfullyPlannedDates
            .add(date); // Tambahkan tanggal yang berhasil direncanakan
      }

      if (mounted) {
        double screenWidth = MediaQuery.of(context).size.width;
        double fontSize =
            screenWidth * 0.035; // Adjust font size based on screen width

        if (successfullyPlannedDates.isNotEmpty) {
          // Tampilkan SnackBar untuk tanggal yang berhasil direncanakan
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.add_task_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Recipe planned for ${successfullyPlannedDates.length} day(s)',
                    style: TextStyle(fontSize: fontSize), // Dynamic font size
                  ),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Tampilkan SnackBar jika semua tanggal adalah duplikat
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'No new plans were added. All selected plans already exist.',
                    style: TextStyle(fontSize: fontSize), // Dynamic font size
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Perbarui status rencana di UI
        setState(() {
          plannedStatus[recipe.id] = true; // Tandai sebagai direncanakan
        });
      }
    } catch (e) {
      print('Error saving plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to save plan: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecipes() async {
    try {
      // Jika sedang refresh, langsung ambil data baru
      if (_isRefreshing) {
        final recommended = await _mealDBService.getRecommendedRecipes();
        final popular = await _mealDBService.getPopularRecipes();
        final feed = await _mealDBService.getFeedRecipes();

        // Cache data baru
        await _cacheService.cacheRecipes(
            CacheService.RECOMMENDED_CACHE_KEY, recommended);
        await _cacheService.cacheRecipes(
            CacheService.POPULAR_CACHE_KEY, popular);
        await _cacheService.cacheRecipes(CacheService.FEED_CACHE_KEY, feed);

        if (mounted) {
          setState(() {
            recommendedRecipes = recommended;
            popularRecipes = popular;
            feedRecipes = feed;
            isLoading = false;
          });
        }
        return;
      }

      // Initial load - coba load dari cache dulu
      final cachedRecommended = await _cacheService
          .getCachedRecipes(CacheService.RECOMMENDED_CACHE_KEY);
      final cachedPopular =
          await _cacheService.getCachedRecipes(CacheService.POPULAR_CACHE_KEY);
      final cachedFeed =
          await _cacheService.getCachedRecipes(CacheService.FEED_CACHE_KEY);

      if (cachedRecommended != null &&
          cachedPopular != null &&
          cachedFeed != null) {
        setState(() {
          recommendedRecipes = cachedRecommended;
          popularRecipes = cachedPopular;
          feedRecipes = cachedFeed;
          isLoading = false;
        });
      } else {
        // Jika tidak ada cache, fetch data baru
        final recommended = await _mealDBService.getRecommendedRecipes();
        final popular = await _mealDBService.getPopularRecipes();
        final feed = await _mealDBService.getFeedRecipes();

        await _cacheService.cacheRecipes(
            CacheService.RECOMMENDED_CACHE_KEY, recommended);
        await _cacheService.cacheRecipes(
            CacheService.POPULAR_CACHE_KEY, popular);
        await _cacheService.cacheRecipes(CacheService.FEED_CACHE_KEY, feed);

        if (mounted) {
          setState(() {
            recommendedRecipes = recommended;
            popularRecipes = popular;
            feedRecipes = feed;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
      errorMessage = null;
    });

    await _loadRecipes();
    await _loadRecentlyViewedRecipes();

    setState(() {
      _isRefreshing = false;
    });
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
        case 1: // Home
          if (index == 1) {
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
          await _handleRefresh();
          print(
              'Planner page refreshed'); // Ganti dengan metode refresh Planner
          break;
        case 3: // Saved
          if (index == 3) {
            // Saved
            _refreshIndicatorKey.currentState?.show();
          }
          // Tambahkan logika untuk me-refresh halaman Saved
          await _handleRefresh();
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
    await _firestoreService.addToRecentlyViewed(recipe);
    if (mounted) {
      await Navigator.push(
        context,
        SlideUpRoute(page: RecipeDetailPage(recipe: recipe)),
      );
      // Reload recently viewed recipes setelah kembali
      await _loadRecentlyViewedRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _currentIndex == 1
          ? null
          : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            SlideUpRoute(page: const ChatPage()),
          );
        },
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
      // Remove floating action button
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar? _buildAppBar() {
    // Only show AppBar for Home page (index 0)
    if (_currentIndex != 0) {
      return null;
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo_NutriGuide.png',
            width: 33.5,
            height: 33.5,
          ),
          const SizedBox(width: 10),
          Text(
            'NutriGuide',
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              SlideLeftRoute(page: const NotificationsPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              SlideLeftRoute(page: const ProfilePage()),
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
          child: SavedPage(),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideLeftRoute(
                        page: AllRecipesPage(title: title, recipes: recipes)),
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
                      // Gradient Overlay
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
                      ),

                      // Top Area Buttons
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Area Tag
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.03,
                                ),
                              ),
                            ),

                            // More Options Button with Improved Dropdown
                            _buildRecipeOptionsMenu(recipe),
                          ],
                        ),
                      ),

                      // Bottom Content
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.04,
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
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.favorite,
                                    color: _getHealthScoreColor(
                                        recipe.healthScore),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.healthScore.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: _getHealthScoreColor(
                                          recipe.healthScore),
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                    ),
                                  ),
                                ],
                              ),
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
      ],
    );
  }

// Extracted method for recipe options menu
  Widget _buildRecipeOptionsMenu(Recipe recipe) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      offset: const Offset(0, 50),
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 200,
      ),
      iconSize: 24,
      color: Colors.grey[900],
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
        ),
        child: const Icon(
          Icons.more_vert,
          color: Colors.white,
        ),
      ),
      onSelected: (String value) {
        if (value == 'Save Recipe') {
          _toggleSave(recipe);
        } else if (value == 'Plan Meal') {
          _togglePlan(recipe);
        }
      },
      itemBuilder: (BuildContext context) => [
        // Save Recipe Item
        PopupMenuItem<String>(
          height: 60,
          value: 'Save Recipe',
          child: _buildPopupMenuItem(
            icon: savedStatus[recipe.id] == true
                ? Icons.bookmark
                : Icons.bookmark_border_rounded,
            text: savedStatus[recipe.id] == true ? 'Saved' : 'Save Recipe',
            iconColor: savedStatus[recipe.id] == true
                ? Colors.deepOrange
                : Colors.white,
            textColor: savedStatus[recipe.id] == true
                ? Colors.deepOrange
                : Colors.white,
          ),
        ),
        // Plan Meal Item
        PopupMenuItem<String>(
          height: 60,
          value: 'Plan Meal',
          child: _buildPopupMenuItem(
            icon: Icons.calendar_today_rounded,
            text: 'Plan Meal',
            iconColor: Colors.white,
            textColor: Colors.white,
          ),
        ),
      ],
    );
  }

// Helper method to build consistent popup menu items
  Widget _buildPopupMenuItem({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
            Text(
              'Oops! Something Went Wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width *
                    0.05, // Responsive font size based on screen width
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.white70,
                fontSize: MediaQuery.of(context).size.width *
                    0.05, // Adjust font size based on screen width
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recentlyViewedRecipes.isNotEmpty) ...[
                    _buildRecipeSection(
                        'Recently Viewed', recentlyViewedRecipes),
                  ],
                  _buildRecipeSection('Recommended', recommendedRecipes),
                  _buildRecipeSection('Popular', popularRecipes),
                ],
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recipe Feed',
            style: TextStyle(
              color: Colors.white,
              fontSize: MediaQuery.of(context).size.width * 0.05,
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
              onTap: () => _viewRecipe(recipe),
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
                    // Gradient Overlay
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
                    ),

                    // Top Area Buttons
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Area Tag
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ),

                          // More Options Button with Improved Dropdown
                          _buildFeedRecipeOptionsMenu(recipe),
                        ],
                      ),
                    ),

                    // Bottom Content
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.05,
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
                                    color: _getHealthScoreColor(
                                        recipe.healthScore),
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04,
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.04,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      ],
    );
  }

// Extracted method for recipe options menu with unique name
  Widget _buildFeedRecipeOptionsMenu(Recipe recipe) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      offset: const Offset(0, 50),
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 200,
      ),
      iconSize: 24,
      color: Colors.grey[900],
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
        ),
        child: const Icon(
          Icons.more_vert,
          color: Colors.white,
        ),
      ),
      onSelected: (String value) {
        if (value == 'Save Recipe') {
          _toggleSave(recipe);
        } else if (value == 'Plan Meal') {
          _togglePlan(recipe);
        }
      },
      itemBuilder: (BuildContext context) => [
        // Save Recipe Item
        PopupMenuItem<String>(
          height: 60,
          value: 'Save Recipe',
          child: _buildFeedPopupMenuItem(
            icon: savedStatus[recipe.id] == true
                ? Icons.bookmark
                : Icons.bookmark_border_rounded,
            text: savedStatus[recipe.id] == true ? 'Saved' : 'Save Recipe',
            iconColor: savedStatus[recipe.id] == true
                ? Colors.deepOrange
                : Colors.white,
            textColor: savedStatus[recipe.id] == true
                ? Colors.deepOrange
                : Colors.white,
          ),
        ),
        // Plan Meal Item
        PopupMenuItem<String>(
          height: 60,
          value: 'Plan Meal',
          child: _buildFeedPopupMenuItem(
            icon: Icons.calendar_today_rounded,
            text: 'Plan Meal',
            iconColor: Colors.white,
            textColor: Colors.white,
          ),
        ),
      ],
    );
  }

// Helper method to build consistent popup menu items with unique name
  Widget _buildFeedPopupMenuItem({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) async {
        await _handleNavigationTap(index);
      },
      backgroundColor: Colors.deepOrange,
      selectedItemColor: const Color.fromARGB(255, 255, 201, 32),
      unselectedItemColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: MediaQuery.of(context).size.width *
          0.04, // Ukuran font untuk label yang dipilih
      unselectedFontSize: MediaQuery.of(context).size.width *
          0.035, // Ukuran font untuk label yang tidak dipilih

      iconSize: 25, // Ukuran ikon
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_rounded),
          label: 'Planner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border_rounded),
          label: 'Saved',
        ),
      ],
    );
  }
}
