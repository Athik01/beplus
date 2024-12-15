import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
class ManageProducts extends StatefulWidget {
  final String userId;

  ManageProducts({required this.userId});

  @override
  _ManageProductsState createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  final TextEditingController _searchController = TextEditingController();
  late CollectionReference categories;
  String searchQuery = '';
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    categories = FirebaseFirestore.instance.collection('categories');
    _searchController.addListener(_updateSearchQuery);
  }

  void _updateSearchQuery() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal, // Vibrant app bar color
        title: isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search categories...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
        )
            : const Text(
          '      Manage Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.cancel : Icons.search,
              color: Colors.white, // Set the color to white
              size: 24.0, // You can adjust the size as needed
            ),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  isSearching = false;
                  _searchController.clear();
                  searchQuery = '';
                } else {
                  isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20), // Add space between button and list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: categories.where('userId', isEqualTo: widget.userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No categories found.'));
                  }

                  // Filter categories based on the search query
                  var categoryList = snapshot.data!.docs
                      .where((category) {
                    var name = category['name'] ?? '';
                    return name.toLowerCase().contains(searchQuery);
                  })
                      .toList();

                  return ListView.builder(
                    itemCount: categoryList.length,
                    itemBuilder: (context, index) {
                      var category = categoryList[index];

                      // Get image data
                      final String image = category['image'] ?? '';
                      ImageProvider? imageProvider;

                      // Check if the image field contains an URL (https://)
                      if (image.startsWith('https://')) {
                        // Use NetworkImage if it's an HTTPS URL
                        imageProvider = NetworkImage(image);
                      } else {
                        // Decode Base64 if it's not a URL
                        final Uint8List? imageBytes = image.isNotEmpty ? base64Decode(image) : null;
                        if (imageBytes != null) {
                          imageProvider = MemoryImage(imageBytes);
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // Rounded corners
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                            image: imageProvider != null
                                ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.4),
                                BlendMode.darken,
                              ),
                            )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              if (imageProvider == null)
                                const Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      'No Image Available',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 20,
                                child: Text(
                                  category['name'] ?? 'Unnamed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the dialog for adding a category
          showDialog(
            context: context,
            builder: (BuildContext context) => AddItemDialog(userId: widget.userId),
          );
        },
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white, // Set the icon color to white
        ),
        backgroundColor: Colors.teal, // Match button color to the theme
        tooltip: 'Add Category',
      ),
    );
  }
}



class AddItemDialog extends StatelessWidget {
  final String userId;
  AddItemDialog({required this.userId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Add Category or Product',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.category, color: Colors.blue),
            title: Text(
              'Add Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCategoryScreen(userId: userId),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.shopping_cart, color: Colors.green),
            title: Text(
              'Add Product',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AddCategoryScreen extends StatefulWidget {
  final String userId;
  AddCategoryScreen({required this.userId});

  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}
class _AddCategoryScreenState extends State<AddCategoryScreen> {
  bool isLoading = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  XFile? _imageFile;

  Future<void> _addCategory() async {
    if (nameController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        _imageFile != null) {
      setState(() {
        isLoading = true;
      });

      try {
        final file = File(_imageFile!.path);
        final imageBytes = await file.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        await FirebaseFirestore.instance.collection('categories').add({
          'name': nameController.text,
          'userId': widget.userId,
          'description': descriptionController.text,
          'image': base64Image,
          'createdAt': Timestamp.now(),
        });

        setState(() {
          isLoading = false;
        });

        Navigator.pop(context);
      } catch (error) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields and pick an image.')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    } else {
      print("No image selected.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '         Add New Category',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent[200],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 4, // Adds a shadow to the AppBar for a more modern look
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns elements to the left
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _imageFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 70,
                        color: Colors.blue[600],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Pick an Image',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_imageFile!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Category Name',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter category name',
                  hintStyle: TextStyle(color: Colors.blue[400]),
                  prefixIcon: Icon(Icons.category, color: Colors.blue[700]),
                  filled: true,
                  fillColor: Colors.blue[50],
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[300]!, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Category Description',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'Enter category description',
                  hintStyle: TextStyle(color: Colors.blue[400]),
                  prefixIcon: Icon(Icons.description, color: Colors.blue[700]),
                  filled: true,
                  fillColor: Colors.blue[50],
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[300]!, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 32),
              isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Colors.blue[700],
                ),
              )
                  : ElevatedButton(
                onPressed: _addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  elevation: 3, // Adds shadow for better visibility
                ),
                child: Text(
                  'Add Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}





class AddProductScreen extends StatefulWidget {
  final String userId;
  AddProductScreen({required this.userId});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController customCategoryController = TextEditingController();
  XFile? _imageFile;
  bool isLoading = false;

  List<String> selectedSize = [];  // No default size
  String? selectedCategory; // No default category
  List<String> sizes = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']; // Product sizes
  List<String> categories = [];
  bool isCategoriesFetched = false;
  List<String> visibility = [];
  Map<String, Map<String, dynamic>> sizePrices = {};
  String image = 'https://img.freepik.com/premium-vector/product-concept-line-icon-simple-element-illustration-product-concept-outline-symbol-design-can-be-used-web-mobile-ui-ux_159242-2076.jpg';
  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when screen initializes
  }
  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    } else {
      print("No image selected.");
    }
  }
  void _showSizePriceDialog(BuildContext context, String size) {
    TextEditingController priceController = TextEditingController();
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.green[50], // Background color
          title: Text(
            'Enter Price and Quantity for Size: $size',
            style: TextStyle(
              color: Colors.green[800], // Title color
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price input field
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    labelStyle: TextStyle(
                      color: Colors.green[700], // Label color
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: Colors.green[700], // Icon color
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 16), // Spacer
                // Quantity input field
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: TextStyle(
                      color: Colors.green[700], // Label color
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.inventory,
                      color: Colors.green[700], // Icon color
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.green[700], // Text color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                String enteredPrice = priceController.text;
                String enteredQuantity = quantityController.text;
                if (enteredPrice.isNotEmpty && enteredQuantity.isNotEmpty) {
                  setState(() {
                    // Parse the values and add them to the sizePrices map
                    double price = double.tryParse(enteredPrice) ?? 0.0;
                    int quantity = int.tryParse(enteredQuantity) ?? 0;
                    // Store as a map with price and quantity
                    sizePrices[size] = {'price': price, 'quantity': quantity};
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Add Price & Quantity',
                style: TextStyle(
                  color: Colors.white, // Text color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  // Add product to Firestore
  Future<void> _addProduct() async {
    setState(() {
      isLoading = true;
    });
    final file = File(_imageFile!.path);
    final imageBytes = await file.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    FirebaseFirestore.instance.collection('products').add({
      'userId': widget.userId,
      'name': nameController.text,
      'description': descriptionController.text,
      'size': selectedSize,
      'category': selectedCategory,
      'price': sizePrices,
      'visibility':visibility,
      'imageUrl': base64Image, // Store the image path (or URL if uploaded to Firebase Storage)
      'createdAt': Timestamp.now(),
    }).then((value) {
      Navigator.pop(context); // Go back to the ManageProducts screen after adding
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      // Handle error
    });
  }
  Future<void> _fetchCategories() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('userId', isEqualTo: widget.userId) // Filter by userId
          .get();

      final fetchedCategories = querySnapshot.docs.map((doc) => doc['name'] as String).toList();

      setState(() {
        categories = fetchedCategories;
        isCategoriesFetched = true;
        if (categories.isEmpty) {
          categories.add('Custom Categories');
        }
      });
    } catch (e) {
      // Handle error
      print('Error fetching categories: $e');
    }
  }
  void _showCustomCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Enter Custom Category',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: customCategoryController,
            decoration: InputDecoration(
              hintText: 'Enter category',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                String customCategory = customCategoryController.text.trim();
                if (customCategory.isNotEmpty && !categories.contains(customCategory)) {
                  FirebaseFirestore.instance.collection('categories').add({
                    'userId': widget.userId,
                    'name': customCategory,
                    'image': image,
                    'description':'100% Customer Satisfaction!',
                    'createdAt': Timestamp.now(),
                  }).then((_) {
                    setState(() {
                      categories.add(customCategory);
                      selectedCategory = customCategory; // Set selected category
                    });
                  });
                }
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(backgroundColor: Colors.grey[700]),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to show dialog for custom size input
  void _showCustomSizeDialog(BuildContext context) {
    TextEditingController customSizeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Enter Custom Size',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Make the title bold
            ),
          ),
          content: TextField(
            controller: customSizeController,
            decoration: InputDecoration(
              hintText: 'Enter size',
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey), // Grey border when focused
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey), // Grey border when enabled
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red, // Red background for the cancel button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // No rounded corners
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white, // White text color for the cancel button
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                String customSize = customSizeController.text.trim();
                if (customSize.isNotEmpty && !sizes.contains(customSize)) {
                  setState(() {
                    sizes.add(customSize); // Add the custom size to the list
                  });
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[700], // Grey background for the OK button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // No rounded corners
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.white, // White text color for the OK button
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          '        Add New Product',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: isCategoriesFetched
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker section
            _imageFile == null
                ? GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.green[700],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Pick an Image',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                : GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(_imageFile!.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Product Name TextField
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                labelStyle: TextStyle(color: Colors.green[800]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.shopping_cart, color: Colors.green),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 15),

            // Product Description TextField
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Product Description',
                labelStyle: TextStyle(color: Colors.green[800]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.description, color: Colors.green),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 15),

            // Product Size Chips
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ...sizes.map<Widget>((size) {
                  return ChoiceChip(
                    label: Text(
                      size,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedSize.contains(size) ? Colors.white : Colors.green[500],
                      ),
                    ),
                    selected: selectedSize.contains(size),
                    selectedColor: Colors.green[500],
                    backgroundColor: Colors.green[50],
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          // Show the price input dialog when a size is selected
                          if (!selectedSize.contains(size)) {
                            selectedSize.add(size);
                            _showSizePriceDialog(context, size);
                          }
                        } else {
                          // Remove the size and associated price/quantity data if deselected
                          selectedSize.remove(size);
                          sizePrices.remove(size);
                        }
                      });
                    },
                  );
                }).toList(),
                ChoiceChip(
                  label: Text(
                    '+',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.green[500],
                    ),
                  ),
                  selected: false,
                  backgroundColor: Colors.green[50],
                  onSelected: (bool selected) {
                    _showCustomSizeDialog(context);
                  },
                ),
              ],
            ),
            SizedBox(height: 20),



            // Product Category Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.green[50], // Background color matching the theme
                border: Border.all(
                  color: Colors.green, // Border color
                  width: 1.5, // Border width
                ),
                borderRadius: BorderRadius.circular(8), // Rounded corners
              ),
              child: DropdownButtonHideUnderline( // Hides the default underline
                child: DropdownButton<String>(
                  value: selectedCategory,
                  onChanged: (String? newCategory) {
                    if (newCategory == 'Custom Categories') {
                      _showCustomCategoryDialog(context);
                    } else {
                      setState(() {
                        selectedCategory = newCategory;
                      });
                    }
                  },
                  items: categories.map<DropdownMenuItem<String>>((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Colors.green[800], // Text color for items
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  hint: Text(
                    'Select Product Category',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  dropdownColor: Colors.green[50], // Dropdown background color
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.green, // Icon color
                    size: 28,
                  ),
                  style: TextStyle(
                    color: Colors.green[900], // Text color inside dropdown
                    fontSize: 16,
                  ),
                  isExpanded: true, // Makes the dropdown full-width
                ),
              ),
            ),
            SizedBox(height: 20),

            // Add Product Button
            isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.green))
                : Center(
              child: ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Add Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          : Center(child: CircularProgressIndicator(color: Colors.green)),
    );
  }
}


class EditProductScreen extends StatelessWidget {
  final String userId;
  final String productId;

  EditProductScreen({required this.userId, required this.productId});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Fetch product details from Firestore
    CollectionReference products = FirebaseFirestore.instance.collection('products');
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: FutureBuilder<DocumentSnapshot>(
        future: products.doc(productId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Product not found.'));
          }

          var product = snapshot.data!;

          // Initialize controllers with existing product data
          nameController.text = product['name'];
          priceController.text = product['price'].toString();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Product Price'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Update product in Firestore
                    products.doc(productId).update({
                      'name': nameController.text,
                      'price': double.tryParse(priceController.text) ?? 0.0,
                    }).then((value) {
                      Navigator.pop(context); // Go back after editing
                    });
                  },
                  child: Text('Update Product'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
