import 'recipe.dart';

class PlannedMeal {
  final Recipe recipe;
  final String mealType;
  final DateTime dateKey;

  PlannedMeal({
    required this.recipe,
    required this.mealType,
    required this.dateKey,
  });
} 