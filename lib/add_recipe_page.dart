import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'models/recipe.dart';


class AddRecipePage extends StatefulWidget {
  const AddRecipePage({Key? key}) : super(key: key);

  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  String title = '';
  String description = '';
  List<String> ingredients = [''];
  List<String> instructions = [''];
  int cookTimeMinutes = 30;
  String imageUrl = '';
  bool isLoading = false;

  void _updateImageUrl(String url) {
    setState(() {
      imageUrl = url;
    });
  }

  void _addIngredient() {
    setState(() {
      ingredients.add('');
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      ingredients.removeAt(index);
    });
  }

  void _updateIngredient(int index, String value) {
    setState(() {
      ingredients[index] = value;
    });
  }

  void _addInstruction() {
    setState(() {
      instructions.add('');
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      instructions.removeAt(index);
    });
  }

  void _updateInstruction(int index, String value) {
    setState(() {
      instructions[index] = value;
    });
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // TODO: Implement recipe saving
        // For now, we'll just show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe saved successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recipe: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add recipe',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _saveRecipe,
            child: Text(
              'Save',
              style: TextStyle(
                color: isLoading ? Colors.grey : Colors.deepOrange,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Section
            const Text(
              'Title',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Give your recipe a name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a recipe title';
                }
                return null;
              },
              onChanged: (value) => title = value,
            ),
            const SizedBox(height: 24),

            // Photo Section
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Enter image URL',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _updateImageUrl,
            ),
            const SizedBox(height: 16),
            if (imageUrl.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.image,
                    color: Colors.deepOrange,
                    size: 48,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Description Section
            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Introduce your recipe, add notes, cooking tips, serving suggestions, etc...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => description = value,
            ),
            const SizedBox(height: 24),

            // Ingredients Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add, color: Colors.deepOrange),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(
              ingredients.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter ingredient',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an ingredient';
                          }
                          return null;
                        },
                        onChanged: (value) => _updateIngredient(index, value),
                      ),
                    ),
                    if (ingredients.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeIngredient(index),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Instructions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addInstruction,
                  icon: const Icon(Icons.add, color: Colors.deepOrange),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(
              instructions.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter instruction step',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an instruction';
                          }
                          return null;
                        },
                        onChanged: (value) => _updateInstruction(index, value),
                      ),
                    ),
                    if (instructions.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeInstruction(index),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cook Time Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cook time',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Show time picker or number input dialog
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => _CookTimeDialog(
                        initialTime: cookTimeMinutes,
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        cookTimeMinutes = result;
                      });
                    }
                  },
                  child: Text(
                    'Set time',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),
              ],
            ),
            Text(
              '$cookTimeMinutes minutes',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CookTimeDialog extends StatefulWidget {
  final int initialTime;

  const _CookTimeDialog({
    Key? key,
    required this.initialTime,
  }) : super(key: key);

  @override
  _CookTimeDialogState createState() => _CookTimeDialogState();
}

class _CookTimeDialogState extends State<_CookTimeDialog> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Set cook time',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (_minutes > 5) _minutes -= 5;
                  });
                },
              ),
              Text(
                '$_minutes minutes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _minutes += 5;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _minutes),
          child: const Text('Set', style: TextStyle(color: Colors.deepOrange)),
        ),
      ],
    );
  }
}

