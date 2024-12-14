import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/themealdb_service.dart';
import 'recipe_detail_page.dart';
import 'services/firestore_service.dart';
import 'services/cache_service.dart';
import 'package:intl/intl.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
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

class _SearchPageState extends State<SearchPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TheMealDBService _mealDBService = TheMealDBService();
  final CacheService _cacheService = CacheService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> savedStatus = {};
  final Map<String, bool> plannedStatus = {};
  List<Recipe> recipes = [];
  List<Recipe> searchResults = [];
  List<Map<String, String>> popularIngredients = [];
  bool isLoading = false;
  String selectedIngredient = '';
  String sortBy = 'Newest';
  bool _showPopularSection = true;
  bool _isSearching = false;
  bool _isYouMightAlsoLikeSectionExpanded = true;

  DateTime _selectedDate = DateTime.now();
  String _selectedMeal = 'Dinner';
  List<bool> _daysSelected = List.generate(7, (index) => false);

  @override
  void initState() {
    super.initState();
    _loadInitialRecipes().then((_) {
      // Check saved status for each recipe after loading
      for (var recipe in recipes) {
        _checkIfSaved(recipe);
        _checkIfPlanned(recipe);
      }
    });
    _loadPopularIngredients();
    _scrollController.addListener(_onScroll);
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

  void _viewRecipe(Recipe recipe) async {
    await _firestoreService.addToRecentlyViewed(recipe);
    if (mounted) {
      await Navigator.push(
        context,
        SlideUpRoute(page: RecipeDetailPage(recipe: recipe)),
      );
    }
  }

  void _showMealSelectionDialog(BuildContext context, StateSetter setDialogState, Recipe recipe) {
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
              padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Meal Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Meal type selection
                  ListView(
                    shrinkWrap: true,
                    children: ['Breakfast', 'Lunch', 'Dinner', 'Supper', 'Snacks'].map((String mealType) {
                      return ListTile(
                        title: Text(
                          mealType,
                          style: const TextStyle(color: Colors.white, fontSize: 16,),
                        ),
                        onTap: () {
                          // Update the selected meal in the parent dialog
                          setDialogState(() {
                            _selectedMeal = mealType;
                          });
                          // Close both dialogs
                          Navigator.of(context).pop(); // Close meal selection dialog
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
      backgroundColor: Colors.grey[900], // Background untuk dark mode
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan navigasi antar minggu
                  const Text(
                    'Choose Day',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Pindah ke minggu sebelumnya
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
                      Text(
                        // Menampilkan rentang tanggal minggu
                        '${DateFormat('MMM dd').format(_selectedDate)} - '
                            '${DateFormat('MMM dd').format(_selectedDate.add(const Duration(days: 6)))}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Pindah ke minggu berikutnya
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
                          _showMealSelectionDialog(context, setDialogState, recipe);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedMeal.isEmpty ? 'Select Meal' : _selectedMeal,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
                  Wrap(
                    spacing: 8,
                    children: [
                      for (int i = 0; i < 7; i++)
                        ChoiceChip(
                          label: Text(
                            DateFormat('EEE').format(
                              _selectedDate.add(Duration(
                                  days: i - _selectedDate.weekday % 7)),
                            ), // Menampilkan hari dimulai dari Sunday
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
                            color:
                            _daysSelected[i] ? Colors.white : Colors.grey,
                          ),
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
                          if (_selectedMeal.isEmpty || !_daysSelected.contains(true)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select at least one day and a meal type!')),
                            );
                            return;
                          }
                          _saveSelectedPlan(recipe); // Pass the recipe
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white
                        ),
                        child: const Text('Done', style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ) ,),
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
      List<DateTime> successfullyPlannedDates = []; // Untuk menyimpan tanggal yang berhasil direncanakan

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

        successfullyPlannedDates.add(date); // Tambahkan tanggal yang berhasil direncanakan
      }

      if (mounted) {
        if (successfullyPlannedDates.isNotEmpty) {
          // Tampilkan SnackBar untuk tanggal yang berhasil direncanakan
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.add_task_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Recipe planned for ${successfullyPlannedDates.length} day(s)'),
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
                  Text('No new plans were added. All selected plans already exist.', style: TextStyle(fontSize: 13),),
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
                      : Colors.red
              ),
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

  Future<void> _loadInitialRecipes() async {
    setState(() {
      isLoading = true;
    });
    try {
      final recipes = await _mealDBService.getRandomRecipes(number: 30);
      setState(() {
        this.recipes = recipes;
        _sortRecipes();
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
      // Try to get cached ingredients first
      final cachedIngredients = await _cacheService.getCachedIngredients();
      if (cachedIngredients != null) {
        setState(() {
          popularIngredients = cachedIngredients;
        });
        return;
      }

      // If no cache, fetch from API
      final ingredients = await _mealDBService.getPopularIngredients();
      await _cacheService.cacheIngredients(ingredients);
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
      final recipes =
          await _mealDBService.searchRecipesByIngredient(ingredient);
      setState(() {
        this.recipes = recipes;
        isLoading = false;
      });

      for (var recipe in recipes) {
        _checkIfSaved(recipe);
      }
    } catch (e) {
      print('Error searching recipes by ingredient: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  void _openRecipeDetail(Recipe recipe) async {
    try {
      // Tambahkan ke recently viewed
      await _firestoreService.addToRecentlyViewed(recipe);
      if (mounted) {
        // Check if widget is still mounted
        await Navigator.push(
          context,
          SlideUpRoute(
            page: RecipeDetailPage(recipe: recipe),
          ),
        );
      }
    } catch (e) {
      print('Error opening recipe detail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening recipe')),
        );
      }
    }
  }

  void _sortRecipes() {
    setState(() {
      switch (sortBy) {
        case 'Newest':
          recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Popular':
          recipes.sort((a, b) => b.popularity.compareTo(a.popularity));
          break;
        case 'Rating':
          recipes.sort((a, b) => b.healthScore.compareTo(a.healthScore));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '', // Judul halaman (belum ada konten)
            style: TextStyle(
              color: Colors.deepOrange,
<<<<<<< HEAD
              fontSize: MediaQuery.of(context).size.width * 0.06, // Responsif
=======
              fontSize: 24,
>>>>>>> parent of acaba58 (responsif search page)
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Hanya tampilkan pencarian utama saat tidak mencari
        if (!_isSearching)
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
<<<<<<< HEAD
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
=======
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
>>>>>>> parent of acaba58 (responsif search page)
                    child: Text(
                      'Popular Ingredients',
                      style: TextStyle(
                        color: Colors.white,
<<<<<<< HEAD
                        fontSize: MediaQuery.of(context).size.width *
                            0.05, // Responsif
=======
                        fontSize: 20,
>>>>>>> parent of acaba58 (responsif search page)
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
                          onTap: () =>
                              _searchRecipesByIngredient(ingredient['name']!),
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
<<<<<<< HEAD
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      MediaQuery.of(context).size.width < 360
                                          ? 12 // Ukuran untuk perangkat kecil
                                          : MediaQuery.of(context).size.width *
                                              0.035, // Responsif
=======
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
>>>>>>> parent of acaba58 (responsif search page)
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
<<<<<<< HEAD
                    fontSize:
                        MediaQuery.of(context).size.width * 0.05, // Responsif
=======
                    fontSize: 20,
>>>>>>> parent of acaba58 (responsif search page)
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: sortBy,
                  onSelected: (String value) {
                    setState(() {
                      sortBy = value;
                      _sortRecipes();
                    });
                  },
                  offset: const Offset(0, 40), // Mengatur posisi popup di bawah icon
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15), // Menambahkan border radius
                  ),
                  constraints: const BoxConstraints( // Mengatur ukuran minimum popup
                    minWidth: 180, // Lebar minimum
                    maxWidth: 180, // Lebar maksimum
                  ),
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
                      height: 50, // Menambah tinggi setiap item
                      child: Text(
                        'Newest',
<<<<<<< HEAD
                        style: TextStyle(color: Colors.white),
=======
                        style: TextStyle(
                            color: Colors.white,
                        ),
>>>>>>> parent of acaba58 (responsif search page)
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Popular',
                      height: 50, // Menambah tinggi setiap item
                      child: Text(
                        'Popular',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Rating',
                      height: 50, // Menambah tinggi setiap item
                      child: Text(
                        'Rating',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange))
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
        // Move the back button and title row closer to the top
        Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, bottom: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              ),
              const SizedBox(width: 5),
              const Text(
                'Search Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Reduce padding and spacing around the search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17.5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search Recipes...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _searchRecipes(value);
                }
              },
            ),
          ),
        ),
        // Remove or reduce the SizedBox height
        const SizedBox(height: 10),
        // Expand the search results to take up more space
        Expanded(
          child: _buildRecipeGrid(searchResults),
        ),
        // Conditionally render the "You might also like" section
        if (searchResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: 15,
              bottom: 0,
              left: 15,
              right: 15,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You might also like',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Add an IconButton to toggle the section
                IconButton(
                  icon: Icon(
                    _isYouMightAlsoLikeSectionExpanded
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      _isYouMightAlsoLikeSectionExpanded =
                          !_isYouMightAlsoLikeSectionExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          // Only show the grid when section is expanded
          if (_isYouMightAlsoLikeSectionExpanded)
            SizedBox(
              height:
                  MediaQuery.of(context).size.height * 0.21, // Reduced height
              child: _buildRecipeGrid(recipes.take(10).toList(),
                  scrollDirection: Axis.horizontal),
            ),
        ],
      ],
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipeList,
      {Axis scrollDirection = Axis.vertical}) {
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
          onTap: () => _viewRecipe(recipe),
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
                              _togglePlan(recipe);
                            }
                          },
                          color: Colors.grey[900],
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      savedStatus[recipe.id] == true
                                          ? Icons.bookmark
                                          : Icons.bookmark_border_rounded,
                                      size: 22,
                                      color: savedStatus[recipe.id] == true
                                          ? Colors.deepOrange
                                          : Colors.white, // Mengubah warna icon menjadi putih
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
                                            : Colors.white, // Mengubah warna text menjadi putih
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 22,
                                      color: Colors.white, // Mengubah warna icon menjadi putih
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Plan Meal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white, // Mengubah warna text menjadi putih
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
                                  color:
                                      _getHealthScoreColor(recipe.healthScore),
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
