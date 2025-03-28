import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/themealdb_service.dart';
import 'services/firestore_service.dart';
import 'recipe_detail_page.dart';
import 'all_recipes_page.dart';
import 'search_page.dart';
import 'saved_page.dart';
import 'profile_page.dart';
import 'planner_page.dart';
import 'package:intl/intl.dart';
import 'services/cache_service.dart';
import 'assistant_page.dart';
import 'home_notifications_page.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/constants/font_sizes.dart';
import 'core/helpers/responsive_helper.dart';
import 'widgets/skeleton_loading.dart';

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
  bool _isLoadingRecentlyViewed = true;
  bool _isLoadingRecommended = true;
  bool _isLoadingPopular = true;
  bool _isLoadingFeed = true;
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
      return AppColors.error;
    } else if (score <= 7.5) {
      return AppColors.accent;
    } else {
      return AppColors.success;
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
    BuildContext context,
    StateSetter setDialogState,
    Recipe recipe
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusL),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter mealSetState) {
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: Dimensions.paddingXL,
                horizontal: Dimensions.paddingL
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Meal Type',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.heading3
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingM),
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
                            color: AppColors.text,
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(
                              context,
                              FontSizes.body
                            ),
                          ),
                        ),
                        onTap: () {
                          setDialogState(() {
                            _selectedMeal = mealType;
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          _showPlannedDialog(recipe);
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: ResponsiveHelper.getAdaptiveTextSize(
                              context,
                              FontSizes.body
                            ),
                          ),
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
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusL),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Padding(
              padding: EdgeInsets.symmetric(
                vertical: Dimensions.paddingL,
                horizontal: Dimensions.paddingL
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Day',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.heading3
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                          });
                        },
                        icon: Icon(
                          Icons.arrow_left_rounded,
                          size: Dimensions.iconXL,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        '${DateFormat('MMM dd').format(_selectedDate)} - '
                        '${DateFormat('MMM dd').format(_selectedDate.add(const Duration(days: 6)))}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getAdaptiveTextSize(
                            context,
                            FontSizes.body
                          ),
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 7));
                          });
                        },
                        icon: Icon(
                          Icons.arrow_right_rounded,
                          size: Dimensions.iconXL,
                          color: AppColors.text,
                        ),
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
                              Text(
                                _selectedMeal.isEmpty
                                    ? 'Select Meal'
                                    : _selectedMeal,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.05, // Adjust font size based on screen width
                                ),
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
                  // Pilihan hari menggunakan ChoiceChip (dimulai dari Sunday)
                  // Inside the Wrap widget where you create the ChoiceChip components,
// modify the code to show both day and date:

                  Wrap(
                    spacing: 8,
                    children: [
                      for (int i = 0; i < 7; i++)
                        ChoiceChip(
                          label: Text(
                            // Format as "Sun, 09", "Mon, 10", etc.
                            DateFormat('EEE, dd').format(
                              _selectedDate.add(Duration(days: i)),
                            ),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.caption),
                              color: _daysSelected[i] ? Colors.white : Colors.grey,
                            ),
                          ),
                          selected: _daysSelected[i],
                          onSelected: (bool selected) {
                            setDialogState(() {
                              _daysSelected[i] = selected;
                            });
                          },
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.grey[800],
                          labelStyle: TextStyle(
                            color: _daysSelected[i] ? Colors.white : Colors.grey,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tombol aksi
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
                        // Inside dialog's ElevatedButton onPressed
                        onPressed: () {
                          if (_selectedMeal.isEmpty ||
                              !_daysSelected.contains(true)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please select at least one day and a meal type!')),
                            );
                            return;
                          }
                          _saveSelectedPlan(recipe); // Pass the recipe
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width *
                                0.04, // Adjust font size based on screen width
                            fontWeight: FontWeight.bold,
                          ),
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
  Future<void> _saveSelectedPlan(Recipe recipe) async {
    try {
      List<DateTime> selectedDates = [];
      List<DateTime> successfullyPlannedDates = [];

      for (int i = 0; i < _daysSelected.length; i++) {
        if (_daysSelected[i]) {
          DateTime selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day + i,
          );
          selectedDates.add(selectedDate);
        }
      }

      for (DateTime date in selectedDates) {
        bool exists = await _firestoreService.checkIfPlanExists(
          recipe.id,
          _selectedMeal,
          date,
        );

        if (!exists) {
          await _firestoreService.addPlannedRecipe(
            recipe,
            _selectedMeal,
            date,
          );
          successfullyPlannedDates.add(date);
        }
      }

      if (mounted) {
        if (successfullyPlannedDates.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.add_task_rounded,
                    color: AppColors.text,
                    size: Dimensions.iconM,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Text(
                    'Recipe planned for ${successfullyPlannedDates.length} day(s)',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.body
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: AppColors.text,
                    size: Dimensions.iconM,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Expanded(
                    child: Text(
                      'No new plans were added. All selected plans already exist.',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context,
                          FontSizes.body
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.info,
            ),
          );
        }

        setState(() {
          plannedStatus[recipe.id] = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: AppColors.text,
                  size: Dimensions.iconM,
                ),
                SizedBox(width: Dimensions.paddingS),
                Expanded(
                  child: Text(
                    'Failed to save plan: $e',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                        context,
                        FontSizes.body
                      ),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadRecipes() async {
    try {
      if (_isRefreshing) {
        // Load all recipes simultaneously for refresh
        final recommended = await _mealDBService.getRecommendedRecipes();
        final popular = await _mealDBService.getPopularRecipes();
        final feed = await _mealDBService.getFeedRecipes();

        await _cacheService.cacheRecipes(
          CacheService.RECOMMENDED_CACHE_KEY,
          recommended
        );
        await _cacheService.cacheRecipes(
          CacheService.POPULAR_CACHE_KEY,
          popular
        );
        await _cacheService.cacheRecipes(
          CacheService.FEED_CACHE_KEY,
          feed
        );

        if (mounted) {
          setState(() {
            recommendedRecipes = recommended;
            popularRecipes = popular;
            feedRecipes = feed;
            _isLoadingRecommended = false;
            _isLoadingPopular = false;
            _isLoadingFeed = false;
            isLoading = false;
          });
        }
        return;
      }

      // Try to load from cache first
      final cachedRecommended = await _cacheService.getCachedRecipes(
        CacheService.RECOMMENDED_CACHE_KEY
      );
      final cachedPopular = await _cacheService.getCachedRecipes(
        CacheService.POPULAR_CACHE_KEY
      );
      final cachedFeed = await _cacheService.getCachedRecipes(
        CacheService.FEED_CACHE_KEY
      );

      // Load recently viewed recipes first
      _loadRecentlyViewedRecipes();

      // Load other recipes in parallel
      if (cachedRecommended != null) {
        setState(() {
          recommendedRecipes = cachedRecommended;
          _isLoadingRecommended = false;
        });
      } else {
        _loadRecommendedRecipes();
      }

      if (cachedPopular != null) {
        setState(() {
          popularRecipes = cachedPopular;
          _isLoadingPopular = false;
        });
      } else {
        _loadPopularRecipes();
      }

      if (cachedFeed != null) {
        setState(() {
          feedRecipes = cachedFeed;
          _isLoadingFeed = false;
        });
      } else {
        _loadFeedRecipes();
      }

      // Update overall loading state
      if (mounted) {
        setState(() {
          isLoading = _isLoadingRecentlyViewed || 
                      _isLoadingRecommended || 
                      _isLoadingPopular || 
                      _isLoadingFeed;
        });
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

  Future<void> _loadRecentlyViewedRecipes() async {
    try {
      final recipes = await _firestoreService.getRecentlyViewedRecipes();
      if (mounted) {
        setState(() {
          recentlyViewedRecipes = recipes;
          _isLoadingRecentlyViewed = false;
          isLoading = _isLoadingRecommended || 
                      _isLoadingPopular || 
                      _isLoadingFeed;
        });
      }
    } catch (e) {
      print('Error loading recently viewed recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecentlyViewed = false;
          isLoading = _isLoadingRecommended || 
                      _isLoadingPopular || 
                      _isLoadingFeed;
        });
      }
    }
  }

  Future<void> _loadRecommendedRecipes() async {
    try {
      final recipes = await _mealDBService.getRecommendedRecipes();
      if (mounted) {
        setState(() {
          recommendedRecipes = recipes;
          _isLoadingRecommended = false;
          isLoading = _isLoadingRecentlyViewed || 
                      _isLoadingPopular || 
                      _isLoadingFeed;
        });
        await _cacheService.cacheRecipes(
          CacheService.RECOMMENDED_CACHE_KEY,
          recipes
        );
      }
    } catch (e) {
      print('Error loading recommended recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommended = false;
          isLoading = _isLoadingRecentlyViewed || 
                      _isLoadingPopular || 
                      _isLoadingFeed;
        });
      }
    }
  }

  Future<void> _loadPopularRecipes() async {
    try {
      final recipes = await _mealDBService.getPopularRecipes();
      if (mounted) {
        setState(() {
          popularRecipes = recipes;
          _isLoadingPopular = false;
          isLoading = _isLoadingRecentlyViewed || 
                      _isLoadingRecommended || 
                      _isLoadingFeed;
        });
        await _cacheService.cacheRecipes(
          CacheService.POPULAR_CACHE_KEY,
          recipes
        );
      }
    } catch (e) {
      print('Error loading popular recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingPopular = false;
          isLoading = _isLoadingRecentlyViewed || 
                      _isLoadingRecommended || 
                      _isLoadingFeed;
        });
      }
    }
  }

  Future<void> _loadFeedRecipes() async {
    try {
      final recipes = await _mealDBService.getFeedRecipes();
      if (mounted) {
        setState(() {
          feedRecipes = recipes;
          _isLoadingFeed = false;
          isLoading = _isLoadingRecentlyViewed || 
                      _isLoadingRecommended || 
                      _isLoadingPopular;
        });
        await _cacheService.cacheRecipes(
          CacheService.FEED_CACHE_KEY,
          recipes
        );
      }
    } catch (e) {
      print('Error loading feed recipes: $e');
      if (mounted) {
        setState(() {
          _isLoadingFeed = false;
          isLoading = _isLoadingRecentlyViewed || 
                      _isLoadingRecommended || 
                      _isLoadingPopular;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
      errorMessage = null;
      _isLoadingRecentlyViewed = true;
      _isLoadingRecommended = true;
      _isLoadingPopular = true;
      _isLoadingFeed = true;
    });

    await _loadRecipes();
    await _loadRecentlyViewedRecipes();

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _handleNavigationTap(int index) async {
    if (_currentIndex == index) {
      switch (index) {
        case 0:
          _refreshIndicatorKey.currentState?.show();
          await _handleRefresh();
          break;
        case 1:
          _refreshIndicatorKey.currentState?.show();
          await _handleRefresh();
          break;
        case 2:
          _refreshIndicatorKey.currentState?.show();
          await _handleRefresh();
          break;
        case 3:
          _refreshIndicatorKey.currentState?.show();
          await _handleRefresh();
          break;
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _viewRecipe(Recipe recipe) async {
    await _firestoreService.addToRecentlyViewed(recipe);
    if (mounted) {
      await Navigator.push(
        context,
        RecipePageRoute(recipe: recipe),
      );
      await _loadRecentlyViewedRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(Dimensions.paddingL),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(Dimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.primary,
                      size: Dimensions.iconXL,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingL),
                  Text(
                    'Exit NutriGuide',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.heading3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingM),
                  Text(
                    'Are you sure you want to exit the app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                    ),
                  ),
                  SizedBox(height: Dimensions.spacingXL),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: Dimensions.paddingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Dimensions.radiusM),
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Dimensions.spacingM),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              vertical: Dimensions.paddingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Dimensions.radiusM),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Exit',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.body),
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
          ),
        ) ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  AppBar? _buildAppBar() {
    if (_currentIndex != 0) return null;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo_NutriGuide.png',
            width: Dimensions.iconXL,
            height: Dimensions.iconXL,
          ),
          SizedBox(width: Dimensions.paddingS),
          Text(
            'NutriGuide',
            style: TextStyle(
              color: AppColors.text,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(
                context, 
                FontSizes.heading2
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined, 
            color: AppColors.text,
            size: Dimensions.iconM,
          ),
          onPressed: () {
            Navigator.push(
              context,
              SlideLeftRoute(page: const HomeNotificationsPage()),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.person, 
            color: AppColors.text,
            size: Dimensions.iconM,
          ),
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
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: _buildHomeContent(),
        );
      case 1:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: isLoading 
            ? const SearchSkeleton() 
            : const SearchPage(),
        );
      case 2:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: isLoading 
            ? const PlannerSkeleton() 
            : const PlannerPage(),
        );
      case 3:
        return RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppColors.primary,
          child: isLoading 
            ? const SavedSkeleton() 
            : const SavedPage(),
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildMoreButton(Recipe recipe) {
    return Container(
      width: Dimensions.iconL,
      height: Dimensions.iconL,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.5),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: Dimensions.iconM,
        icon: Icon(
          Icons.more_vert,
          color: AppColors.text,
        ),
        onSelected: (String value) {
          if (value == 'Save Recipe') {
            _toggleSave(recipe);
          } else if (value == 'Plan Meal') {
            _togglePlan(recipe);
          }
        },
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
        ),
        offset: const Offset(0, 45),
        constraints: BoxConstraints(
          minWidth: ResponsiveHelper.screenWidth(context) * 0.41,
          maxWidth: ResponsiveHelper.screenWidth(context) * 0.41,
        ),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            height: 60,
            value: 'Save Recipe',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    savedStatus[recipe.id] == true
                        ? Icons.bookmark
                        : Icons.bookmark_border_rounded,
                    size: Dimensions.iconM,
                    color: savedStatus[recipe.id] == true
                        ? AppColors.primary
                        : AppColors.text,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Text(
                    savedStatus[recipe.id] == true ? 'Saved' : 'Save Recipe',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context,
                          FontSizes.body
                      ),
                      color: savedStatus[recipe.id] == true
                          ? AppColors.primary
                          : AppColors.text,
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
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: Dimensions.iconM,
                    color: AppColors.text,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Text(
                    'Plan Meal',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context,
                          FontSizes.body
                      ),
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButtonFeed(Recipe recipe) {
    return Padding(
      padding: EdgeInsets.only(
        top: 1.5,
      ),
      child: Container(
      width: 37.5,
      height: 37.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.5),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: Dimensions.iconM,
        icon: Icon(
          Icons.more_vert,
          color: AppColors.text,
        ),
        onSelected: (String value) {
          if (value == 'Save Recipe') {
            _toggleSave(recipe);
          } else if (value == 'Plan Meal') {
            _togglePlan(recipe);
          }
        },
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
        ),
        offset: const Offset(0, 45),
        constraints: BoxConstraints(
          minWidth: ResponsiveHelper.screenWidth(context) * 0.41,
          maxWidth: ResponsiveHelper.screenWidth(context) * 0.41,
        ),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            height: 60,
            value: 'Save Recipe',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    savedStatus[recipe.id] == true
                        ? Icons.bookmark
                        : Icons.bookmark_border_rounded,
                    size: Dimensions.iconM,
                    color: savedStatus[recipe.id] == true
                        ? AppColors.primary
                        : AppColors.text,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Text(
                    savedStatus[recipe.id] == true ? 'Saved' : 'Save Recipe',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context,
                          FontSizes.body
                      ),
                      color: savedStatus[recipe.id] == true
                          ? AppColors.primary
                          : AppColors.text,
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
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: Dimensions.iconM,
                    color: AppColors.text,
                  ),
                  SizedBox(width: Dimensions.paddingS),
                  Text(
                    'Plan Meal',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                          context,
                          FontSizes.body
                      ),
                      color: AppColors.text,
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
    );
  }

  Widget _buildRecipeSection(String title, List<Recipe> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingM,
            vertical: ResponsiveHelper.screenHeight(context) * 0.0015,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(
                    context,
                    FontSizes.heading3
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideLeftRoute(
                      page: AllRecipesPage(title: title, recipes: recipes)
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                      context,
                      FontSizes.body
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ResponsiveHelper.screenHeight(context) * 0.3,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return GestureDetector(
                onTap: () => _viewRecipe(recipe),
                child: Hero(
                  tag: 'recipe-${recipe.id}',
                  child: Container(
                    width: ResponsiveHelper.screenWidth(context) * 0.525,
                    margin: EdgeInsets.only(
                      left: Dimensions.paddingS,
                      bottom: Dimensions.paddingS,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      image: DecorationImage(
                        image: NetworkImage(recipe.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusM),
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
                        // Content
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.screenHeight(context) * 0.0145,
                            horizontal: ResponsiveHelper.screenWidth(context) * 0.025,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row with area tag and more button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: Dimensions.paddingS,
                                        vertical: Dimensions.paddingXS
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(Dimensions.radiusS),
                                      ),
                                      child: Text(
                                        recipe.area ?? 'International',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: MediaQuery.of(context).size.width * 0.0325,
                                        ),
                                      ),
                                    ),
                                    _buildMoreButton(recipe),
                                  ],
                                ),
                              // Bottom info
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.title,
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: ResponsiveHelper.getAdaptiveTextSize(
                                        context,
                                        FontSizes.body
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: Dimensions.paddingXS),
                                  _buildRecipeInfo(recipe),
                                ],
                              ),
                            ],
                          ),
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

  Widget _buildRecipeInfo(Recipe recipe) {
    return Row(
      children: [
        Icon(
          Icons.timer,
          color: AppColors.text,
          size: Dimensions.iconS,
        ),
        SizedBox(width: Dimensions.paddingXS),
        Text(
          '${recipe.preparationTime} min',
          style: TextStyle(
            color: AppColors.text,
            fontSize: ResponsiveHelper.getAdaptiveTextSize(
              context,
              FontSizes.caption
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.favorite,
          color: _getHealthScoreColor(recipe.healthScore),
          size: Dimensions.iconS,
        ),
        SizedBox(width: Dimensions.paddingXS),
        Text(
          recipe.healthScore.toStringAsFixed(1),
          style: TextStyle(
            color: _getHealthScoreColor(recipe.healthScore),
            fontSize: ResponsiveHelper.getAdaptiveTextSize(
              context,
              FontSizes.caption
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    return ListView(
      children: [
        if (_isLoadingRecentlyViewed)
          _buildSkeletonSection('Recently Viewed')
        else if (recentlyViewedRecipes.isNotEmpty)
          _buildRecipeSection('Recently Viewed', recentlyViewedRecipes),

        if (_isLoadingRecommended)
          _buildSkeletonSection('Recommended')
        else
          _buildRecipeSection('Recommended', recommendedRecipes),

        if (_isLoadingPopular)
          _buildSkeletonSection('Popular')
        else
          _buildRecipeSection('Popular', popularRecipes),

        SizedBox(height: Dimensions.paddingL),

        if (_isLoadingFeed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Recipe Feed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                      context,
                      FontSizes.heading3
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return RecipeFeedSkeleton();
                },
              ),
            ],
          )
        else
          _buildRecipeFeed(),
      ],
    );
  }

  Widget _buildSkeletonSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingM,
            vertical: ResponsiveHelper.screenHeight(context) * 0.0015,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: ResponsiveHelper.getAdaptiveTextSize(
                    context,
                    FontSizes.heading3
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: null,
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(
                      context,
                      FontSizes.body
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ResponsiveHelper.screenHeight(context) * 0.3,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return RecipeCardSkeleton(
                width: ResponsiveHelper.screenWidth(context) * 0.525,
                height: ResponsiveHelper.screenHeight(context) * 0.3
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Recipe Feed',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.getAdaptiveTextSize(
                  context,
                  FontSizes.heading3
              ), // Adjust font size based on screen width
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width *
                                  0.05, // Adjust font size based on screen width
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
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.04, // Adjust font size based on screen width
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
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.screenHeight(context) * 0.0125,
                        horizontal: ResponsiveHelper.screenWidth(context) * 0.025,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(recipe.area ?? 'International',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: MediaQuery.of(context).size.width * 0.035, // Adjust font size based on screen width
                                ),
                            ),
                          ),
                          _buildMoreButtonFeed(recipe),
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
    return Padding(
      padding: EdgeInsets.all(Dimensions.paddingM),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingM, 
                  vertical: Dimensions.paddingXS
                ),
                height: 65,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                    ),
                    Flexible(
                      child: _buildNavItem(1, Icons.search_outlined, Icons.search_rounded, 'Search'),
                    ),
                    SizedBox(width: Dimensions.paddingXS),
                    _buildCenterNavItem(),
                    SizedBox(width: Dimensions.paddingXS),
                    Flexible(
                      child: _buildNavItem(2, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Planner'),
                    ),
                    Flexible(
                      child: _buildNavItem(3, Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Saved'),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8 * value,
                  offset: Offset(0, 4 * value),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.chat_bubble_rounded,
                color: AppColors.surface,
                size: Dimensions.iconM,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  SlideUpRoute(page: const AssistantPage()),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _handleNavigationTap(index),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        builder: (context, double value, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingXS),
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 1 + (0.2 * value),
                  child: Container(
                    padding: EdgeInsets.all(value * Dimensions.paddingXS),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        AppColors.primary.withOpacity(0.1),
                        value,
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: Color.lerp(
                        AppColors.textSecondary,
                        AppColors.primary,
                        value,
                      ),
                      size: Dimensions.iconM,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Color.lerp(
                      AppColors.textSecondary,
                      AppColors.primary,
                      value,
                    ),
                    fontSize: ResponsiveHelper.getAdaptiveTextSize(context, FontSizes.caption) - 1,
                    fontWeight: FontWeight.lerp(
                      FontWeight.normal,
                      FontWeight.w600,
                      value,
                    ),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _setLoading(bool loading) {
    setState(() {
      isLoading = loading;
    });
  }
}

class CurvedPainter extends CustomPainter {
  final int selectedIndex;
  final Color color;

  CurvedPainter({required this.selectedIndex, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    
    final itemWidth = size.width / 4;
    final curveHeight = 20.0;
    
    path.moveTo(0, 0);
    path.lineTo(itemWidth * selectedIndex, 0);
    
    path.quadraticBezierTo(
      itemWidth * selectedIndex + itemWidth / 2,
      curveHeight,
      itemWidth * (selectedIndex + 1),
      0,
    );
    
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
