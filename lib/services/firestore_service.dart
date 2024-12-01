import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Existing methods...

  Future<void> saveUserPersonalization(Map<String, dynamic> data) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving user personalization: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserPersonalization() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
        return doc.data() as Map<String, dynamic>?;
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting user personalization: $e');
      rethrow;
    }
  }

  Future<void> saveUserGoals(List<String> goals) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({'goals': goals});
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving user goals: $e');
      rethrow;
    }
  }

  Future<void> saveUserAllergies(List<String> allergies) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({'allergies': allergies});
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving user allergies: $e');
      rethrow;
    }
  }

  // New methods for recipe saving functionality

  Future<void> saveRecipe(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).collection('saved_recipes').doc(recipe.id).set({
          'id': recipe.id,
          'title': recipe.title,
          'image': recipe.image,
          'category': recipe.category,
          'area': recipe.area,
          'instructions': recipe.instructions,
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving recipe: $e');
      rethrow;
    }
  }

  Future<void> unsaveRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .doc(recipeId)
            .delete();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error removing saved recipe: $e');
      rethrow;
    }
  }

  Future<bool> isRecipeSaved(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .doc(recipeId)
            .get();
        return doc.exists;
      }
      return false;
    } catch (e) {
      print('Error checking if recipe is saved: $e');
      return false;
    }
  }

  Future<List<Recipe>> getSavedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
            .orderBy('savedAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            ingredients: List<String>.from(data['ingredients']),
            measurements: List<String>.from(data['measurements']),
            instructions: data['instructions'],
            instructionSteps: data['instructions'].split('\n'),
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            nutritionInfo: NutritionInfo.generateRandom(), // We'll regenerate this since it's not stored
          );
        }).toList();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting saved recipes: $e');
      return [];
    }
  }

  Future<void> saveViewedRecipeIds(List<String> recipeIds) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'viewedRecipeIds': recipeIds,
          'lastViewedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving viewed recipe IDs: $e');
      rethrow;
    }
  }

  // New method to get viewed recipe IDs
  Future<List<String>> getViewedRecipeIds() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

        // Check if the document exists and has viewedRecipeIds
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('viewedRecipeIds')) {
          return List<String>.from(data['viewedRecipeIds'] ?? []);
        }

        return [];
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting viewed recipe IDs: $e');
      return [];
    }
  }

  // Method to save details of viewed recipes
  Future<void> saveViewedRecipeDetails(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('viewed_recipes')
            .doc(recipe.id)
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'image': recipe.image,
          'category': recipe.category,
          'area': recipe.area,
          'instructions': recipe.instructions,
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'viewedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error saving viewed recipe details: $e');
      rethrow;
    }
  }

  // Method to retrieve viewed recipe details
  Future<List<Recipe>> getViewedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('viewed_recipes')
            .orderBy('viewedAt', descending: true)
            .limit(50) // Limit to 50 most recent viewed recipes
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            ingredients: List<String>.from(data['ingredients']),
            measurements: List<String>.from(data['measurements']),
            instructions: data['instructions'],
            instructionSteps: data['instructions'].split('\n'),
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            nutritionInfo: NutritionInfo.generateRandom(), // Regenerate nutrition info
          );
        }).toList();
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting viewed recipes: $e');
      return [];
    }
  }
}

