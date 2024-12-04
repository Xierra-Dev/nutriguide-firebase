import 'package:flutter/material.dart';
import 'models/recipe.dart';
import 'services/firestore_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailPage({super.key, required this.recipe});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  bool isSaved = false;
  bool isLoading = false;
  bool showTitle = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _addToRecentlyViewed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Color _getHealthScoreColor(double? healthScore) {
    if (healthScore == null) return Colors.grey;

    if (healthScore < 6) {
      return Colors.red;
    } else if (healthScore <= 7.5) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
  
  void _onScroll() {
    // You can adjust this value (100) to control when the title appears
    if (_scrollController.offset > 100 && !showTitle) {
      setState(() {
        showTitle = true;
      });
    } else if (_scrollController.offset <= 100 && showTitle) {
      setState(() {
        showTitle = false;
      });
    }
  }

  Future<void> _checkIfSaved() async {
    final saved = await _firestoreService.isRecipeSaved(widget.recipe.id);
    setState(() {
      isSaved = saved;
    });
  }

  Future<void> _addToRecentlyViewed() async {
    try {
      await _firestoreService.addToRecentlyViewed(widget.recipe);
    } catch (e) {
      print('Error adding to recently viewed: $e');
    }
  }

  Future<void> _toggleSave(Recipe recipe) async {
    setState(() {
      isLoading = true;
    });
    try {
      if (isSaved) {
        await _firestoreService.unsaveRecipe(widget.recipe.id);
      } else {
        await _firestoreService.saveRecipe(widget.recipe);
      }
      setState(() {
        isSaved = !isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved ? 'Recipe saved: ${recipe.title}' : 'Recipe: "${recipe.title}" removed from saved',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving recipe'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            expandedHeight: MediaQuery.of(context).size.height * 0.375,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.recipe.image,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.45),
                            Colors.transparent,
                            Colors.black.withOpacity(0.45),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
            ),
            actions: [
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                        top: 5,
                      ),
                      padding: EdgeInsets.only(
                        bottom: 2,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isSaved ? Icons.calendar_today : Icons.calendar_today,
                          color: isSaved ? Colors.deepOrange : Colors.white,
                          size: 20, // Reduced icon size
                        ), // Reduced padding
                        onPressed: isLoading ? null : () => _toggleSave(widget.recipe),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        top: 5,
                        right: 10,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.deepOrange : Colors.white,
                          size: 22.5, // Reduced icon size
                        ), // Reduced padding
                        onPressed: isLoading ? null : () => _toggleSave(widget.recipe),
                      ),
                    ),
                  ],
                ),
            ],

          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 20,
              ),
              child: Column(
                children: [
                  // Removed the Text widget that displayed the recipe title
                  const SizedBox(height: 8),
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildIngredientsList(),
                  const SizedBox(height: 24),
                  _buildInstructions(),
                  const SizedBox(height: 24),
                  _buildHealthScore(),
                  const SizedBox(height: 24),
                  _buildNutritionInfo(widget.recipe.nutritionInfo),
                ],
              ),
            ),
          ),
        ],
      ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(
            top: 18,
            bottom: 15,
            right: 18,
            left: 18,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _toggleSave(widget.recipe),
                  style: ElevatedButton.styleFrom(
                    // Change background color based on save state
                    backgroundColor: isSaved ? Colors.deepOrange : Colors.white,
                    // Change text color based on save state
                    foregroundColor: isSaved ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    ),
                  )
                      : Text(isSaved ? 'Saved' : 'Save', style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700
                  ),),
                ),
              ),
              SizedBox(width: 18,),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _toggleSave(widget.recipe),
                  style: ElevatedButton.styleFrom(
                    // Change background color based on save state
                    backgroundColor: isSaved ? Colors.deepOrange : Colors.white,
                    // Change text color based on save state
                    foregroundColor: isSaved ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    ),
                  )
                      : Text(isSaved ? 'Planned' : 'Plan', style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700
                  ),),
                ),
              ),
            ],
          ),
        )
    );
  }

  // Rest of the widget methods remain the same...
  Widget _buildInfoButton(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoButton('Time', '${widget.recipe.preparationTime} min', Icons.timer),
        _buildInfoButton('Servings', '4', Icons.people),
        _buildInfoButton('Calories', '${widget.recipe.nutritionInfo.calories}', Icons.local_fire_department),
      ],
    );
  }

  Widget _buildIngredientsList() {
    return Column(
      children: [
        const Text(
          'Ingredients',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.recipe.ingredients.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.deepOrange, size: 8),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.recipe.measurements[index]} ${widget.recipe.ingredients[index]}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        const Text(
          'Instructions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.recipe.instructionSteps.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.recipe.instructionSteps[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHealthScore() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: widget.recipe.healthScore / 10,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(_getHealthScoreColor(widget.recipe.healthScore)),
        ),
        SizedBox(height: 8,),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${widget.recipe.healthScore.toStringAsFixed(1)} / 10',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionInfo(NutritionInfo nutritionInfo) {
    return Column(
      children: [
        const Text(
          'Nutrition Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildNutritionRow('Calories', '${nutritionInfo.calories} kcal'),
        _buildNutritionRow('Total Fat', '${nutritionInfo.totalFat.toStringAsFixed(1)}g'),
        _buildNutritionRow('Saturated Fat', '${nutritionInfo.saturatedFat.toStringAsFixed(1)}g'),
        _buildNutritionRow('Carbs', '${nutritionInfo.carbs.toStringAsFixed(1)}g'),
        _buildNutritionRow('Sugars', '${nutritionInfo.sugars.toStringAsFixed(1)}g'),
        _buildNutritionRow('Protein', '${nutritionInfo.protein.toStringAsFixed(1)}g'),
        _buildNutritionRow('Sodium', '${nutritionInfo.sodium}mg'),
        _buildNutritionRow('Fiber', '${nutritionInfo.fiber.toStringAsFixed(1)}g'),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}