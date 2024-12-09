import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import 'dart:io' show File;
import 'storage_service.dart';
import 'package:intl/intl.dart';
import '../models/planned_recipe.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  // Existing methods...

  Future<void> saveUserPersonalization(Map<String, dynamic> data) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .set(data, SetOptions(merge: true));
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
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        } else {
          // Return null if no data exists
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting user personalization: $e');
      rethrow;
    }
  }

  Future<void> saveUserGoals(List<String> goals) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'goals': goals});
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
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'allergies': allergies});
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
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('saved_recipes')
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

  Future<void> removeFromSavedRecipes(Recipe recipe) async {
    try {
      // Assuming you're using Firebase Authentication and have the current user
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Reference to the Firestore collection of saved recipes for this user
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('saved_recipes')
          .doc(recipe.id) // Assuming the recipe has a unique ID
          .delete();
    } catch (e) {
      print('Error removing recipe from saved: $e');
      rethrow;
    }
  }


  Future<bool> isRecipePlanned(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .doc(recipeId)
            .get();
        return doc.exists;
      }
      return false;
    } catch (e) {
      print('Error checking if recipe is planned: $e');
      return false;
    }
  }

  Future<List<Recipe>> getPlannedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .orderBy('plannedAt', descending: true)
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
      print('Error getting planned recipes: $e');
      return [];
    }
  }

  Future<void> removePlannedRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Menghapus dokumen dengan ID tertentu dari koleksi planned_recipes
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .doc(recipeId)
            .delete();
        print('Planned recipe removed: $recipeId');
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error removing planned recipe: $e');
      rethrow;
    }
  }

  Future<void> addPlannedRecipe(Recipe recipe, String mealType, DateTime selectedDate) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Normalisasi tanggal ke midnight untuk konsistensi
        final normalizedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );

        // Periksa apakah rencana sudah ada
        bool exists = await checkIfPlanExists(recipe.id, mealType, normalizedDate);
        if (exists) {
          print('Duplicate plan detected for recipe: ${recipe.title} on $normalizedDate');
          throw Exception('Duplicate plan detected'); // Lempar error untuk penanganan lebih lanjut
        }

        String plannedId = '${recipe.id}_${normalizedDate.millisecondsSinceEpoch}';

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .doc(plannedId)
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
          'plannedAt': FieldValue.serverTimestamp(),
          'plannedDate': Timestamp.fromDate(normalizedDate), // Gunakan tanggal yang dinormalisasi
          'mealType': mealType,
        });
        print('Planned recipe added: ${recipe.title} for date: $normalizedDate, type: $mealType'); // Debug print
      }
    } catch (e) {
      print('Error adding planned recipe: $e');
      rethrow;
    }
  }

  Future<bool> checkIfPlanExists(String recipeId, String mealType, DateTime selectedDate) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Normalisasi tanggal ke midnight untuk konsistensi
        final normalizedDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );

        final querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('planned_recipes')
            .where('id', isEqualTo: recipeId)
            .where('mealType', isEqualTo: mealType)
            .where('plannedDate', isEqualTo: Timestamp.fromDate(normalizedDate))
            .get();

        return querySnapshot.docs.isNotEmpty; // Jika ada dokumen, berarti duplikat
      }
      return false;
    } catch (e) {
      print('Error checking for duplicate plan: $e');
      rethrow;
    }
  }


  Future<void> addToRecentlyViewed(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('recently_viewed')
            .doc(recipe.id)
            .set({
          'id': recipe.id,
          'title': recipe.title,
          'category': recipe.category,
          'area': recipe.area,
          'image': recipe.image,
          'preparationTime': recipe.preparationTime,
          'healthScore': recipe.healthScore,
          'viewedAt': FieldValue.serverTimestamp(),
          // Add these fields
          'ingredients': recipe.ingredients,
          'measurements': recipe.measurements,
          'instructions': recipe.instructions,
        });
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error adding to recently viewed: $e');
      rethrow;
    }
  }

  Future<List<Recipe>> getRecentlyViewedRecipes({int limit = 10}) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('recently_viewed')
            .orderBy('viewedAt', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Recipe(
            id: data['id'],
            title: data['title'],
            image: data['image'],
            category: data['category'],
            area: data['area'],
            preparationTime: data['preparationTime'],
            healthScore: data['healthScore'].toDouble(),
            // Update these fields to use stored data
            ingredients: List<String>.from(data['ingredients'] ?? []),
            measurements: List<String>.from(data['measurements'] ?? []),
            instructions: data['instructions'] ?? '',
            instructionSteps: (data['instructions'] ?? '').split('\n'),
            nutritionInfo: NutritionInfo.generateRandom(),
          );
        }).toList();
      } else {
        print('No authenticated user found');
        return [];
      }
    } catch (e) {
      print('Error getting recently viewed recipes: $e');
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('Permission denied. Please check Firebase security rules.');
      }
      return [];
    }
  }
  // Tambahkan metode ini di dalam kelas FirestoreService

  Future<String?> getCurrentUserUsername() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();

        // Periksa apakah dokumen ada dan memiliki field username
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('username')) {
          return userData['username'];
        }

        return null;
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      final imageUrl =
          await _storageService.uploadProfilePicture(imageFile, userId);
      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': imageUrl,
      });
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update(data);
    }
  }

  Future<List<String>> getUserGoals() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['goals'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting user goals: $e');
      return [];
    }
  }

  Future<List<String>> getUserAllergies() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['allergies'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting user allergies: $e');
      return [];
    }
  }

  Future<Map<String, List<PlannedMeal>>> getPlannedMeals() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('planned_recipes')
          .orderBy('plannedDate')
          .get();
      
      Map<String, List<PlannedMeal>> meals = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Raw data from Firestore: $data'); // Debug print
        
        final recipe = Recipe(
          id: data['id'],
          title: data['title'],
          image: data['image'],
          category: data['category'],
          area: data['area'],
          instructions: data['instructions'],
          ingredients: List<String>.from(data['ingredients']),
          measurements: List<String>.from(data['measurements']),
          preparationTime: data['preparationTime'],
          healthScore: data['healthScore'].toDouble(),
          instructionSteps: data['instructions'].split('\n'),
          nutritionInfo: NutritionInfo.generateRandom(),
        );

        final date = (data['plannedDate'] as Timestamp).toDate();
        // Normalisasi tanggal untuk key
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        print('Date from Firestore: $date, DateKey: $dateKey'); // Debug print
        
        final plannedMeal = PlannedMeal(
          recipe: recipe,
          mealType: data['mealType'],
          dateKey: date,
        );
        
        if (!meals.containsKey(dateKey)) {
          meals[dateKey] = [];
        }
        meals[dateKey]!.add(plannedMeal);
      }
      
      print('Final meals map: $meals'); // Debug print
      return meals;
    } catch (e) {
      print('Error in getPlannedMeals: $e');
      throw Exception('Failed to load planned meals: $e');
    }
  }

  Future<void> deletePlannedMeal(PlannedMeal meal) async {
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      String plannedId = '${meal.recipe.id}_${meal.dateKey.millisecondsSinceEpoch}';
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('planned_recipes')
          .doc(plannedId)
          .delete();
    }
  }

  Future<List<Recipe>> getUserCreatedRecipes() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      print('Fetching recipes for user: $userId'); // Debug print

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('created_recipes')
          .get();

      print('Found ${snapshot.docs.length} recipes'); // Debug print

      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Recipe data from Firestore: $data'); // Debug print

        return Recipe(
          id: doc.id,
          title: data['title'],
          image: data['image'],
          category: data['category'],
          area: data['area'],
          instructions: data['instructions'],
          ingredients: List<String>.from(data['ingredients']),
          measurements: List<String>.from(data['measurements']),
          preparationTime: data['preparationTime'],
          healthScore: data['healthScore'].toDouble(),
          instructionSteps: data['instructions'].split('\n'),
          nutritionInfo: NutritionInfo.generateRandom(),
        );
      }).toList();
    } catch (e) {
      print('Error getting user created recipes: $e');
      return [];
    }
  }

  Future<void> deleteUserRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('created_recipes')
          .doc(recipeId)
          .delete();
    } catch (e) {
      print('Error deleting user recipe: $e');
      rethrow;
    }
  }

    Future<void> saveUserCreatedRecipe(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      print('Saving recipe for user: $userId'); // Debug print

      final recipeData = {
        'title': recipe.title,
        'image': recipe.image,
        'category': recipe.category,
        'area': recipe.area,
        'instructions': recipe.instructions,
        'ingredients': recipe.ingredients,
        'measurements': recipe.measurements,
        'preparationTime': recipe.preparationTime,
        'healthScore': recipe.healthScore,
        'createdAt': FieldValue.serverTimestamp(),
        'popularity': 0,
      };

      print('Recipe data to save: $recipeData'); // Debug print

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('created_recipes')
          .add(recipeData);
      
      print('Recipe saved to Firestore'); // Debug print
    } catch (e) {
      print('Error in saveUserCreatedRecipe: $e'); // Debug print
      rethrow;
    }
  }

  Future<void> updateUserRecipe(Recipe recipe) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final recipeData = {
        'title': recipe.title,
        'image': recipe.image,
        'category': recipe.category,
        'area': recipe.area,
        'instructions': recipe.instructions,
        'ingredients': recipe.ingredients,
        'measurements': recipe.measurements,
        'preparationTime': recipe.preparationTime,
        'healthScore': recipe.healthScore,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('created_recipes')
          .doc(recipe.id)
          .update(recipeData);
    } catch (e) {
      print('Error updating recipe: $e');
      rethrow;
    }
  }

    Future<List<Recipe>> getRandomRecipes({int number = 10}) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('created_recipes')
          .limit(number)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe(
          id: doc.id,
          title: data['title'],
          image: data['image'],
          ingredients: List<String>.from(data['ingredients']),
          measurements: List<String>.from(data['measurements']),
          instructions: data['instructions'],
          instructionSteps: data['instructions'].split('\n'),
          preparationTime: data['preparationTime'],
          healthScore: data['healthScore'].toDouble(),
          nutritionInfo: NutritionInfo.generateRandom(),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          popularity: data['popularity'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Error getting random recipes: $e');
      return [];
    }
  }

  Future<void> madeRecipe(Recipe recipe, {String? additionalKey}) async {
    try {
      // Use the additionalKey if provided, otherwise use the recipe ID
      final docId = additionalKey ?? recipe.id;

      await _firestore
          .collection('made_recipes')
          .doc(docId)
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
        'madeAt': FieldValue.serverTimestamp(),
        'madeDate': Timestamp.fromDate, // Gunakan tanggal yang dinormalisasi
        // Add any other relevant recipe details
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error marking recipe as made: $e');
      rethrow;
    }
  }

  Future<void> removeMadeRecipe(String docId) async {
    try {
      await _firestore
          .collection('made_recipes')
          .doc(docId)
          .delete();
    } catch (e) {
      print('Error removing made recipe: $e');
      rethrow;
    }
  }

  Future<bool> isRecipeMade(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('made_recipes')
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
}
