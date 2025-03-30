import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Add this package

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
  // Store the edited image bytes (if user picks a new image)
  Uint8List? _editedImageBytes;

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

  // Function to pick a new image using image_picker
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _editedImageBytes = bytes;
      });
    }
  }

  Future<void> _fetchProductDetails() async {
    DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();

    if (productSnapshot.exists) {
      var product = productSnapshot.data() as Map<String, dynamic>;
      nameController.text = product['name'] ?? '';
      descriptionController.text = product['description'] ?? '';
      categoryController.text = product['category'] ?? '';
      // Handle size array
      if (product['size'] != null && product['size'] is List) {
        sizeControllers = (product['size'] as List)
            .map((size) => TextEditingController(text: size.toString()))
            .toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Use the white fading effect background image
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/back.png'),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(1.0), // fully transparent white at the top
            Colors.white.withOpacity(1.0), // fully opaque white at the bottom
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Product Details',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.white,
            ),
          ),
          actions: [
            if (!isEditing)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
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
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else {
              var product =
              snapshot.data!.data() as Map<String, dynamic>;
              String productID = snapshot.data!.id;
              // Use the edited image if available, else the product image
              var imageBytes = _editedImageBytes ??
                  (product['imageUrl'] != null
                      ? base64Decode(product['imageUrl'])
                      : null);
              // Initialize the controllers if not in editing mode
              if (!isEditing) {
                nameController.text = product['name'] ?? '';
                descriptionController.text =
                    product['description'] ?? '';
                categoryController.text = product['category'] ?? '';
                sizeControllers = [];
                priceControllers = [];
                quantityControllers = [];

                // For price map which stores size keys and values
                Map<String, dynamic> priceMap =
                    product['price'] ?? {};
                priceMap.forEach((size, value) {
                  if (value is Map<String, dynamic>) {
                    sizeControllers.add(
                        TextEditingController(text: size.toString()));
                    priceControllers.add(TextEditingController(
                        text: value['price']?.toString() ?? ''));
                    quantityControllers.add(TextEditingController(
                        text: value['quantity']?.toString() ?? ''));
                  }
                });
                // Also, if a separate 'size' list exists, use it
                if (product['size'] != null &&
                    product['size'] is List) {
                  sizeControllers = (product['size'] as List)
                      .map((size) =>
                      TextEditingController(text: size.toString()))
                      .toList();
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // Image with border and edit option
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                  'lib/assets/back2.png'),
                              fit: BoxFit.fill,
                            ),
                            borderRadius:
                            BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(15),
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
                                  colors: [
                                    Colors.grey[300]!,
                                    Colors.grey[400]!
                                  ],
                                  begin:
                                  Alignment.topLeft,
                                  end: Alignment
                                      .bottomRight,
                                ),
                              ),
                              height: 250,
                              width: double.infinity,
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  color:
                                  Colors.grey[600],
                                  size: 80,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isEditing)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: ClipOval(
                              child: Material(
                                color: Colors.black45, // background color for the circular icon
                                child: IconButton(
                                  icon: Icon(Icons.edit_outlined, color: Colors.white),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Product details card with border and background image
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('lib/assets/back2.png'),
                          fit: BoxFit.fill,
                        ),
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('lib/assets/back.png'),
                            fit: BoxFit.cover,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.9), // white at the top with opacity
                              Colors.white.withOpacity(0.0), // transparent at the bottom
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Container(
                            // This container serves as a white overlay behind the text content.
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8), // adjust opacity as needed
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  isEditing
                                      ? _buildTextField(
                                    controller: nameController,
                                    label: 'Name',
                                    color: Colors.blueGrey[800],
                                  )
                                      : _buildDisplayText(
                                    label: product['name'] ?? 'No Name',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[800],
                                  ),
                                  SizedBox(height: 12),
                                  Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                  // Editable or display sizes/prices/quantities
                                  isEditing
                                      ? Column(
                                    children: List.generate(sizeControllers.length, (index) {
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: sizeControllers[index],
                                              label: 'Size',
                                              color: Colors.green,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: priceControllers[index],
                                              label: 'Price',
                                              prefixText: '₹',
                                              keyboardType: TextInputType.number,
                                              color: Colors.green,
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: quantityControllers[index],
                                              label: 'Quantity',
                                              keyboardType: TextInputType.number,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  )
                                      : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for (int i = 0; i < sizeControllers.length; i++)
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.green,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Size: ${sizeControllers[i].text}',
                                                        style: GoogleFonts.montserrat(
                                                          textStyle: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.green,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Price: ₹${priceControllers[i].text}',
                                                        style: GoogleFonts.montserrat(
                                                          textStyle: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.green,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Quantity: ${quantityControllers[i].text}',
                                                        style: GoogleFonts.montserrat(
                                                          textStyle: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.green,
                                                            fontWeight: FontWeight.bold,
                                                          ),
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
                                      SizedBox(height: 16),
                                    ],
                                  ),
                                  Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                  SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Description Field
                                      isEditing
                                          ? _buildTextField(
                                        controller: descriptionController,
                                        label: 'Description',
                                        color: Colors.black87,
                                        maxLines: 3,
                                      )
                                          : Row(
                                        children: [
                                          Icon(
                                            Icons.description,
                                            color: Colors.black87,
                                          ),
                                          SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Description: ${product['description'] ?? 'No description available.'}',
                                              style: GoogleFonts.montserrat(
                                                textStyle: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      // Category Field
                                      isEditing
                                          ? _buildTextField(
                                        controller: categoryController,
                                        label: 'Category',
                                        color: Colors.black87,
                                      )
                                          : Row(
                                        children: [
                                          Icon(
                                            Icons.category,
                                            color: Colors.black87,
                                          ),
                                          SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Category: ${product['category'] ?? 'N/A'}',
                                              style: GoogleFonts.montserrat(
                                                textStyle: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isEditing)
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.end,
                          children: [
                            _buildActionButton(
                              label: 'Cancel',
                              icon: Icons.cancel,
                              color: Colors.grey[500],
                              onPressed: () =>
                                  setState(() => isEditing = false),
                            ),
                            SizedBox(width: 10),
                            _buildActionButton(
                              label: 'Save',
                              icon: Icons.save,
                              color: Colors.blueGrey[800],
                              onPressed: () async {
                                // Prepare updated image data if a new image was picked
                                String? updatedImageBase64;
                                if (_editedImageBytes != null) {
                                  updatedImageBase64 =
                                      base64Encode(_editedImageBytes!);
                                }
                                final updatedData = {
                                  'name': nameController.text.trim(),
                                  'price': {
                                    for (int i = 0;
                                    i < sizeControllers.length;
                                    i++)
                                      sizeControllers[i]
                                          .text
                                          .trim():
                                      {
                                        'price': double.tryParse(
                                            priceControllers[i]
                                                .text
                                                .trim()) ??
                                            product['price']?[sizeControllers[i]
                                                .text
                                                .trim()]['price'] ??
                                            0.0,
                                        'quantity': int.tryParse(
                                            quantityControllers[i]
                                                .text
                                                .trim()) ??
                                            product['price']?[sizeControllers[i]
                                                .text
                                                .trim()]['quantity'] ??
                                            0,
                                      },
                                  },
                                  'description': descriptionController.text
                                      .trim(),
                                  'category': categoryController.text.trim(),
                                  'size': sizeControllers
                                      .map((controller) =>
                                      controller.text.trim())
                                      .where((size) => size.isNotEmpty)
                                      .toList(),
                                  // Update image only if edited
                                  if (updatedImageBase64 != null)
                                    'imageUrl': updatedImageBase64,
                                };

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('products')
                                      .doc(productID)
                                      .update(updatedData);

                                  setState(() {
                                    isEditing = false;
                                    product = {
                                      ...product,
                                      ...updatedData
                                    };
                                    // Reset edited image after save
                                    _editedImageBytes = null;
                                  });

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
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
                                              style: GoogleFonts.montserrat(
                                                textStyle: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.blueGrey,
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                } catch (error) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
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
                                              style: GoogleFonts.montserrat(
                                                textStyle: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
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
      ),
    );
  }
}

// Helper widgets using GoogleFonts.montserrat for all text

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  Color? color,
  String? prefixText,
  TextInputType? keyboardType,
  int maxLines = 1,
  double? width,
  EdgeInsetsGeometry? padding,
}) {
  return Container(
    width: width,
    padding: padding ?? EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        labelStyle: GoogleFonts.montserrat(
          textStyle: TextStyle(color: color),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
              color: color ?? Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: color ?? Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: color ?? Colors.grey, width: 1.5),
        ),
        contentPadding:
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: GoogleFonts.montserrat(
        textStyle:
        TextStyle(fontSize: 18, color: color ?? Colors.black),
      ),
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
    style: GoogleFonts.montserrat(
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    ),
    overflow: TextOverflow.ellipsis,
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
    label: Text(
      label,
      style: GoogleFonts.montserrat(),
    ),
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: color,
      padding:
      EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
    onPressed: onPressed,
  );
}
