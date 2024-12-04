import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class TheMealDBService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<String?> getRandomMealImage() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/random.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return data['meals'][0]['strMealThumb'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching random meal image: $e');
      return null;
    }
  }

  Future<List<Recipe>> getRandomRecipes({int number = 10}) async {
    List<Recipe> recipes = [];
    for (int i = 0; i < number; i++) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/random.php'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null && data['meals'].isNotEmpty) {
            final recipe = Recipe.fromTheMealDB(data['meals'][0]);
            if (_isRecipeComplete(recipe)) {
              recipes.add(recipe);
              print('Added random recipe: ${recipe.title} with health score: ${recipe.healthScore}');
            } else {
              print('Skipped incomplete random recipe: ${recipe.title}');
            }
          }
        } else {
          print('Failed to load random recipe. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching random recipe: $e');
      }
    }
    return recipes;
  }

  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/filter.php?c=$category'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          List<Recipe> recipes = [];
          for (var meal in data['meals']) {
            final detailedRecipe = await getRecipeById(meal['idMeal']);
            if (_isRecipeComplete(detailedRecipe)) {
              recipes.add(detailedRecipe);
              print('Added category recipe: ${detailedRecipe.title} with health score: ${detailedRecipe.healthScore}');
            } else {
              print('Skipped incomplete category recipe: ${detailedRecipe.title}');
            }
          }
          return recipes;
        }
      }
      print('Failed to load recipes for category $category. Status code: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching recipes by category: $e');
      return [];
    }
  }

  Future<Recipe> getRecipeById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/lookup.php?i=$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return Recipe.fromTheMealDB(data['meals'][0]);
        }
      }
      throw Exception('Failed to load recipe details');
    } catch (e) {
      print('Error fetching recipe details: $e');
      rethrow;
    }
  }

  bool _isRecipeComplete(Recipe recipe) {
    return recipe.ingredients.isNotEmpty &&
           recipe.instructionSteps.isNotEmpty &&
           recipe.healthScore > 0; // Changed from 4 to 0 to include more recipes
  }


  Future<List<Map<String, String>>> getPopularIngredients() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list.php?i=list'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          final ingredients = (data['meals'] as List)
              .take(10) // Get the first 10 ingredients
              .map((ingredient) => {
                    'name': ingredient['strIngredient'] as String,
                    'image':
                        'https://www.themealdb.com/images/ingredients/${ingredient['strIngredient']}.png',
                  })
              .toList();
          return ingredients;
        }
      }
      throw Exception('Failed to load popular ingredients');
    } catch (e) {
      print('Error fetching popular ingredients: $e');
      return [];
    }
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/search.php?s=$query'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          return (data['meals'] as List)
              .map((recipeData) => Recipe.fromTheMealDB(recipeData))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

    Future<List<Recipe>> searchRecipesByIngredient(String ingredient) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/filter.php?i=$ingredient'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          List<Recipe> recipes = [];
          for (var meal in data['meals']) {
            final detailedRecipe = await getRecipeById(meal['idMeal']);
            if (_isRecipeComplete(detailedRecipe)) {
              recipes.add(detailedRecipe);
              print('Added category recipe: ${detailedRecipe.title} with health score: ${detailedRecipe.healthScore}');
            } else {
              print('Skipped incomplete category recipe: ${detailedRecipe.title}');
            }
          }
          return recipes;
        }
      }
      print('Failed to load recipes for category $ingredient. Status code: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error fetching recipes by category: $e');
      return [];
    }
  }

}

