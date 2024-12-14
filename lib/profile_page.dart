import 'package:flutter/material.dart';
import 'package:nutriguide/home_page.dart';
import 'settings_page.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'profile_edit_page.dart';
import 'models/recipe.dart';
import 'models/nutrition_goals.dart';
import 'recipe_detail_page.dart';
import 'edit_recipe_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'widgets/nutrition_tracker.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
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
          begin: const Offset(-1.0, 0.0),
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

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isLoadingActivity = true; 
  List<Recipe> activityRecipes = []; 
  bool isLoadingCreated = true;

  final Color selectedColor = const Color.fromARGB(255, 240, 182, 75);

  // Define the daily nutrition variables
  double dailyCalories = 0;
  double dailyProtein = 0;
  double dailyCarbs = 0;
  double dailyFat = 0;

  NutritionGoals nutritionGoals = NutritionGoals.recommended();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadDailyNutritionData();
    _loadActivityData();
    _loadNutritionGoals();

    // Add listener to update state when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  Future<void> _loadNutritionGoals() async {
    final goals = await _firestoreService.getNutritionGoals();
    setState(() {
      nutritionGoals = goals;
    });
  }

  Future<void> _loadActivityData() async {
    try {
      setState(() => isLoadingActivity = true);
      final recipes = await _firestoreService.getMadeRecipes();
      setState(() {
        activityRecipes = recipes;
        isLoadingActivity = false;
      });
    } catch (e) {
      print('Error loading activity data: $e');
      setState(() {
        activityRecipes = [];
        isLoadingActivity = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _firestoreService.getUserPersonalization();
      print('Loaded userData: $data'); // Debug print
      if (data != null) {
        print('Profile Picture URL: ${data['profilePictureUrl']}'); // Debug print
        setState(() {
          userData = data;
          isLoading = false;
        });
      } else {
        print('No user data found');
        setState(() {
          userData = {};
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userData = {};
        isLoading = false;
      });
    }
  }

  Future<void> _loadDailyNutritionData() async {
    try {
      final nutritionTotals = await _firestoreService.getDailyNutritionTotals();
      setState(() {
        dailyCalories = nutritionTotals['calories'] ?? 0;
        dailyProtein = nutritionTotals['protein'] ?? 0;
        dailyCarbs = nutritionTotals['carbs'] ?? 0;
        dailyFat = nutritionTotals['fat'] ?? 0;
      });
    } catch (e) {
      print('Error loading daily nutrition data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      // Add debug print
      print('Building profile page with userData: $userData');
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(
                left: 12,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 27,),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    SlideRightRoute(page: const HomePage()),
                  );
                },
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 2,
                  right: 10,
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      SlideLeftRoute(page: const SettingsPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          body: isLoading
              ? const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange))
              : Column(
            children: [
              const SizedBox(height: 15),
              Center(
                child: Column(
                  children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                    ),
                    child: ClipOval(
                      child: userData != null &&
                            userData!['profilePictureUrl'] != null &&
                            userData!['profilePictureUrl'].toString().isNotEmpty
                          ? Image.network(
                              userData!['profilePictureUrl'],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  print('Image loaded successfully');
                                  return child;
                                }
                                print('Loading image...');
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.deepOrange,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                print('Stack trace: $stackTrace');
                                return const Icon(Icons.person,
                                    size: 50, color: Colors.white);
                              },
                            )
                          : const Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _authService.currentUser?.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (userData != null && userData!['username'] != null && userData!['username'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 7,
                        bottom: 8,
                      ),
                      child: Text(
                        userData!['username'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (userData != null && userData!['bio'] != null && userData!['bio'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 6,
                        bottom: 10,
                      ),
                      child: Text(
                        userData!['bio'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to edit profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileEditPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
              const SizedBox(height: 32),
              TabBar(
                controller: _tabController,
                indicatorColor: selectedColor,
                labelColor: selectedColor,
                unselectedLabelColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 2.5,
                    color: selectedColor,
                  ),
                  insets: EdgeInsets.symmetric(horizontal: 100.0),
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'Insights'),
                  Tab(text: 'Activity'),
                ],
              ),
              const SizedBox(height: 10,),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInsightsTab(),
                    _buildActivityTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildInsightsTab() {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 25,
                horizontal: 17.5,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your daily nutrition goals',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7.5),
                  const Text(
                    'Balanced macros',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutritionItem('Cal', '${nutritionGoals.calories.toStringAsFixed(0)}', Colors.blue),
                      _buildNutritionItem('Carbs', '${nutritionGoals.carbs.toStringAsFixed(0)}g', Colors.orange),
                      _buildNutritionItem('Fiber', '${nutritionGoals.fiber.toStringAsFixed(0)}g', Colors.green),
                      _buildNutritionItem('Protein', '${nutritionGoals.protein.toStringAsFixed(0)}g', Colors.pink),
                      _buildNutritionItem('Fat', '${nutritionGoals.fat.toStringAsFixed(0)}g', Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            NutritionTracker(nutritionGoals: nutritionGoals),
          ],
        ),
      ),
    );
  }


  Widget _buildNutritionItem(String label, String value, Color color) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    if (isLoadingActivity) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: RefreshIndicator(
        onRefresh: _loadActivityData,
        color: Colors.deepOrange,
        child: activityRecipes.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.465,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/no-activity.png',
                            width: 125,
                            height: 125,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No activity yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activityRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = activityRecipes[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Row
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(userData?['profilePictureUrl'] ?? 'default_avatar_url'),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _authService.currentUser?.displayName ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'a moment ago',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Recipe Image
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailPage(recipe: recipe),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Image.network(
                                recipe.image,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Made it ✨',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Recipe Info
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.category ?? 'Recipe',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Button
                        Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.bookmark_border,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  try {
                                    await _firestoreService.saveRecipe(recipe);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Recipe saved to bookmarks'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to save recipe'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}