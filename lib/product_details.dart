import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ProductDetails extends StatefulWidget {
  final String productId;

  ProductDetails({required this.productId});

  @override
  _ProductDetailsState createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late TextEditingController nameController;
  List<TextEditingController> priceControllers = [];
  List<TextEditingController> quantityControllers = [];
  late TextEditingController descriptionController;
  late TextEditingController categoryController;

  List<TextEditingController> sizeControllers = [];

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    categoryController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceControllers.forEach((controller) => controller.dispose());
    quantityControllers.forEach((controller) => controller.dispose());
    descriptionController.dispose();
    categoryController.dispose();
    sizeControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchProductDetails() async {
    DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();

    if (productSnapshot.exists) {
      var product = productSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> priceMap = product['price'] ?? {'price': 0.0, 'quantity': 0};
      nameController.text = product['name'] ?? '';
      descriptionController.text = product['description'] ?? '';
      categoryController.text = product['category'] ?? '';
      // Initial value for the controllers
      // Handle size array
      if (product['size'] != null && product['size'] is List) {
        sizeControllers = (product['size'] as List).map((size) {
          return TextEditingController(text: size.toString());
        }).toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '        Product Details',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
            color: Colors.white, // Sets the text color to white
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 5,
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Colors.white, // Set icon color to white
              ),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .get(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Product not found.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            var product = snapshot.data!.data() as Map<String, dynamic>;
            String productID = snapshot.data!.id;
            var imageBytes = product['imageUrl'] != null
                ? base64Decode(product['imageUrl'])
                : null;
            Map<String, dynamic> priceMap = product['price'] ?? {'price': 0.0, 'quantity': 0};
            print(priceMap);
            // Initialize the editable text controllers with product data if not in edit mode
            if (!isEditing) {
              // Check if 'price' exists and is of type Map
              Map<String, dynamic> priceMap = product['price'] ?? {};

              // Initialize controllers for name, description, and category
              nameController.text = product['name'] ?? '';
              descriptionController.text = product['description'] ?? '';
              categoryController.text = product['category'] ?? '';

              // Initialize controllers for sizes, prices, and quantities
              sizeControllers = [];
              priceControllers = [];
              quantityControllers = [];

              // Iterate over priceMap to fetch sizes as keys and their corresponding values
              priceMap.forEach((size, value) {
                if (value is Map<String, dynamic>) {
                  sizeControllers.add(TextEditingController(text: size.toString()));
                  priceControllers.add(TextEditingController(text: value['price']?.toString() ?? ''));
                  quantityControllers.add(TextEditingController(text: value['quantity']?.toString() ?? ''));
                }
              });

              // Handle sizes separately if they exist
              if (product['size'] != null && product['size'] is List) {
                sizeControllers = (product['size'] as List).map((size) {
                  return TextEditingController(text: size.toString());
                }).toList();
              }
            }


            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageBytes != null
                        ? Image.memory(
                      imageBytes,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[300]!, Colors.grey[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      height: 250,
                      width: double.infinity,
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[600],
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 6),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing)
                            _buildTextField(
                              controller: nameController,
                              label: 'Name',
                              color: Colors.teal[800],
                            )
                          else
                            _buildDisplayText(
                              label: product['name'] ?? 'No Name',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                            ),
                          SizedBox(height: 12),
                          Divider(color: Colors.grey[300], thickness: 1),
                          // Display in edit mode
                          if (isEditing)
                            Column(
                              children: List.generate(sizeControllers.length, (index) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: sizeControllers[index], // Use the individual controller
                                        label: 'Size',
                                        color: Colors.green,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: priceControllers[index], // Use the individual controller
                                        label: 'Price',
                                        prefixText: '₹',
                                        keyboardType: TextInputType.number,
                                        color: Colors.green,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: quantityControllers[index], // Use the individual controller
                                        label: 'Quantity',
                                        keyboardType: TextInputType.number,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < sizeControllers.length; i++)
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100], // Light green background for contrast
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green, // Green border
                                        width: 2, // Border width
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4), // Slight shadow for depth
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Size: ${sizeControllers[i].text}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8), // Space between elements
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Price: ₹${priceControllers[i].text}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8), // Space between elements
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Quantity: ${quantityControllers[i].text}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16), // Added consistent spacing at the bottom
                              ],
                            ),
                          Divider(color: Colors.grey[300], thickness: 1),
                          SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description Field
                              if (isEditing)
                                _buildTextField(
                                  controller: descriptionController,
                                  label: 'Description',
                                  color: Colors.black87,
                                  maxLines: 3,
                                )
                              else
                                Row(
                                  children: [
                                    Icon(Icons.description, color: Colors.black87), // Icon for Description
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Description: ${product['description'] ?? 'No description available.'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),

                              // Category Field
                              if (isEditing)
                                _buildTextField(
                                  controller: categoryController,
                                  label: 'Category',
                                  color: Colors.black87,
                                )
                              else
                                Row(
                                  children: [
                                    Icon(Icons.category, color: Colors.black87), // Icon for Category
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Category: ${product['category'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            label: 'Cancel',
                            icon: Icons.cancel,
                            color: Colors.grey[500],
                            onPressed: () => setState(() => isEditing = false),
                          ),
                          SizedBox(width: 10),
                          _buildActionButton(
                            label: 'Save',
                            icon: Icons.save,
                            color: Colors.teal[800],
                            onPressed: () async {
                              // Ensure fields are valid and not empty
                              final updatedData = {
                                'name': nameController.text.trim(),
                                // Save price and quantity as a map when submitting
                                'price': {
                                  for (int i = 0; i < sizeControllers.length; i++)
                                    sizeControllers[i].text.trim(): {
                                      'price': double.tryParse(priceControllers[i].text.trim()) ?? product['price']?[sizeControllers[i].text.trim()]['price'] ?? 0.0,
                                      'quantity': int.tryParse(quantityControllers[i].text.trim()) ?? product['price']?[sizeControllers[i].text.trim()]['quantity'] ?? 0,
                                    },
                                },
                                'description': descriptionController.text.trim(),
                                'category': categoryController.text.trim(),
                                'size': sizeControllers.map((controller) => controller.text.trim()).where((size) => size.isNotEmpty).toList(),
                              };

                              try {
                                // Firestore update logic
                                await FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(productID) // Ensure the product has a valid 'id' field
                                    .update(updatedData);

                                // Reflect changes locally
                                setState(() {
                                  isEditing = false;
                                  product = {...product, ...updatedData};
                                });

                                // Show confirmation to the user
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Product updated successfully!',
                                            style: TextStyle(fontSize: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.teal,
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              } catch (error) {
                                // Handle errors gracefully
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Failed to update product: $error',
                                            style: TextStyle(fontSize: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  Color? color,
  String? prefixText,
  TextInputType? keyboardType,
  int maxLines = 1,
  double? width, // Added to allow width constraints
  EdgeInsetsGeometry? padding, // Optional padding
}) {
  return Container(
    width: width, // Constrain width if provided
    padding: padding ?? EdgeInsets.symmetric(vertical: 8), // Default padding
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        labelStyle: TextStyle(color: color),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: color ?? Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color ?? Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color ?? Colors.grey, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding inside the text field
      ),
      style: TextStyle(fontSize: 18, color: color ?? Colors.black),
      keyboardType: keyboardType,
      maxLines: maxLines,
    ),
  );
}


Widget _buildDisplayText({
  required String label,
  double fontSize = 16,
  Color? color,
  FontWeight? fontWeight,
}) {
  return Text(
    label,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    ),
    overflow: TextOverflow.ellipsis,
  );
}

Widget _buildSizeDisplay({required List sizes, required Color labelColor}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Sizes:',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 4),
      ...sizes.map<Widget>((size) => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(
          '- $size',
          style: TextStyle(
            fontSize: 16,
            color: labelColor,
          ),
        ),
      )),
    ],
  );
}

Widget _buildActionButton({
  required String label,
  required IconData icon,
  required Color? color,
  required VoidCallback onPressed,
}) {
  return ElevatedButton.icon(
    icon: Icon(icon),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
    onPressed: onPressed,
  );
}