import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPage extends StatelessWidget {
  final String productId;
  final String userId =  FirebaseAuth.instance.currentUser!.uid;
  OrderPage({required this.productId});
  Widget _buildRelatedProducts(String category, String currentProductName) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .limit(5) // Limit to 5 related products
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading related products',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox(); // Don't display the related products section
        }

        final relatedProducts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final visibility = data['visibility'] ?? [];

          // Check if the product is visible to the current user
          final isVisible = visibility.contains(userId);

          // Filter out the current product and products not visible to the user
          return data['name'] != currentProductName && isVisible;
        }).toList();

        if (relatedProducts.isEmpty) {
          return SizedBox(); // Don't display the related products section
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Related Products ⛏ ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: relatedProducts.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final productId = doc.id;
                    final productName = data['name'] ?? 'Unnamed Product';
                    final base64Image = data['imageUrl'];
                    final imageBytes = base64Image != null ? base64Decode(base64Image) : null;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderPage(productId: productId),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              imageBytes != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  imageBytes,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.black45,
                                    size: 40,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  productName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.teal.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: 26,
            ),
            SizedBox(width: 8),
            Text(
              'Order Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade800,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.teal.shade800,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Product Info',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        Text(
                          'This page provides detailed information about the selected product. You can view its specifications, price, and other relevant details.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading product details',
                style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Product not found',
                style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            );
          }

          final productData = snapshot.data!;
          final productId = snapshot.data!.id;
          final productName = productData['name'] ?? 'Unnamed Product';
          final category = productData['category']??'Unknown';
          final description = productData['description'] ?? 'No description available';
          final sizes = productData['size'] as List<dynamic>; // List of sizes
          final priceData = productData['price'] as Map<String, dynamic>; // Map with size, price, and quantity
          final base64Image = productData['imageUrl'];
          final imageBytes = base64Image != null ? base64Decode(base64Image) : null;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageBytes != null
                      ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        imageBytes,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      : Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Image not available',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            productName,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          SizedBox(height: 12),
                          Divider(),
                          SizedBox(height: 12),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400,fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: 12),
                          Divider(),
                          SizedBox(height: 12),
                          Text(
                            'Sizes Available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          sizes.isEmpty
                              ? Text(
                            'No sizes available',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          )
                              : Wrap(
                            spacing: 8, // Space between chips
                            runSpacing: 4, // Space between rows of chips
                            children: sizes.map((size) {
                              final sizeDetails = priceData[size]; // Get the size details
                              final price = sizeDetails['price'] ?? 'N/A';
                              final quantity = sizeDetails['quantity'] ?? 'N/A';

                              return Chip(
                                label: Text(
                                  'Size : $size - Price: $price - Quantity: $quantity',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.teal.shade100, // Background color of the chip
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Padding inside chip
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                Map<String, int> selectedQuantity = {}; // Track selected quantities
                                double totalAmount = 0; // Initialize total amount
                                final sizes = productData['size'] as List<dynamic>; // List of available sizes

                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    // Function to calculate the total amount dynamically
                                    void updateTotalAmount() {
                                      totalAmount = 0;
                                      selectedQuantity.forEach((size, quantity) {
                                        final sizeDetails = priceData[size]!;
                                        final price = sizeDetails['price'];
                                        totalAmount += price * quantity;
                                      });
                                    }

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Select Size and Quantity',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          children: sizes.map((size) {
                                            final sizeDetails = priceData[size]!; // Get details for each size
                                            final price = sizeDetails['price'];
                                            final availableQuantity = sizeDetails['quantity'];

                                            // Initialize quantity to 0 if not already selected
                                            if (!selectedQuantity.containsKey(size)) {
                                              selectedQuantity[size] = 0;
                                            }

                                            return Padding(
                                              padding: EdgeInsets.only(bottom: 16.0), // Spacing between size options
                                              child: Card(
                                                elevation: 5,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Chip(
                                                        label: Text(
                                                          'Size: $size - Price: ₹${price}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        backgroundColor: Colors.teal.shade400,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Available Quantity: $availableQuantity',
                                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                                      ),
                                                      SizedBox(height: 12),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(Icons.remove, color: Colors.teal),
                                                            onPressed: () {
                                                              if (selectedQuantity[size]! > 0) {
                                                                setState(() {
                                                                  selectedQuantity[size] = selectedQuantity[size]! - 1;
                                                                  updateTotalAmount(); // Update total amount
                                                                });
                                                              }
                                                            },
                                                          ),
                                                          Text(
                                                            'Quantity: ${selectedQuantity[size]}',
                                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.add, color: Colors.teal),
                                                            onPressed: () {
                                                              if (selectedQuantity[size]! < availableQuantity) {
                                                                setState(() {
                                                                  selectedQuantity[size] = selectedQuantity[size]! + 1;
                                                                  updateTotalAmount(); // Update total amount
                                                                });
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      Divider(color: Colors.teal.shade100),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context); // Close the dialog
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.teal.shade700,
                                          ),
                                          child: Text('Cancel', style: TextStyle(fontSize: 16)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              final userId = FirebaseAuth.instance.currentUser?.uid; // Get current user's ID
                                              if (userId == null) {
                                                print('User is not logged in');
                                                return;
                                              }

                                              // Define the cart item data
                                              final cartItem = {
                                                'userId': userId,
                                                'productId': productId,
                                                'selectedSize':selectedQuantity,
                                                'totalAmount': totalAmount,
                                                'addedAt': FieldValue.serverTimestamp(), // Optional timestamp
                                              };

                                              // Add to the 'carts' collection
                                              await FirebaseFirestore.instance.collection('carts').add(cartItem);

                                              // Feedback for successful addition
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.add_shopping_cart,
                                                        color: Colors.green,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          'Product added to cart!',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  duration: Duration(seconds: 2),
                                                  backgroundColor: Colors.green[100],
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    side: BorderSide(
                                                      color: Colors.green, // Green border color
                                                      width: 2, // Border width
                                                    ),
                                                  ),
                                                  behavior: SnackBarBehavior.floating,
                                                  elevation: 6,
                                                  margin: EdgeInsets.all(16),
                                                ),
                                              );
                                              Navigator.pop(context);
                                              // Navigate back to the OrderPage
                                              // Assuming OrderPage is the first page in the stack
                                            } catch (e) {
                                              print('Error adding product to cart: $e');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          'Failed to add product to cart',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  duration: Duration(seconds: 3),
                                                  backgroundColor: Colors.red.shade700,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  behavior: SnackBarBehavior.floating,
                                                  elevation: 6,
                                                  margin: EdgeInsets.all(16),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal.shade100,
                                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Add to Cart',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5, // Shadow effect
                            ),
                            icon: Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              '  Add to Cart  ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Show dialog when button is pressed
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  Map<String, int> selectedQuantity = {}; // Track selected quantities
                                  final sizes = productData['size'] as List<dynamic>; // List of available sizes

                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return AlertDialog(
                                        title: Text(
                                          'Select Size and Quantity',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade700,
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            children: sizes.map((size) {
                                              final sizeDetails = priceData[size]!; // Get details for each size
                                              final price = sizeDetails['price'];
                                              final availableQuantity = sizeDetails['quantity'];

                                              // Initialize quantity to 0 if not already selected
                                              if (!selectedQuantity.containsKey(size)) {
                                                selectedQuantity[size] = 0;
                                              }

                                              return Padding(
                                                padding: EdgeInsets.only(bottom: 16.0), // Spacing between size options
                                                child: Card(
                                                  elevation: 5,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Chip(
                                                          label: Text(
                                                            'Size: $size - Price: \₹${price}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                          backgroundColor: Colors.teal.shade400,
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Available Quantity: $availableQuantity',
                                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                                        ),
                                                        SizedBox(height: 12),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(Icons.remove, color: Colors.teal),
                                                              onPressed: () {
                                                                if (selectedQuantity[size]! > 0) {
                                                                  setState(() {
                                                                    selectedQuantity[size] = selectedQuantity[size]! - 1;
                                                                  });
                                                                }
                                                              },
                                                            ),
                                                            Text(
                                                              'Quantity: ${selectedQuantity[size]}',
                                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(Icons.add, color: Colors.teal),
                                                              onPressed: () {
                                                                if (selectedQuantity[size]! < availableQuantity) {
                                                                  setState(() {
                                                                    selectedQuantity[size] = selectedQuantity[size]! + 1;
                                                                  });
                                                                }
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        Divider(color: Colors.teal.shade100),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context); // Close the dialog
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.teal.shade700,
                                            ),
                                            child: Text('Cancel', style: TextStyle(fontSize: 16)),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Handle the purchase logic
                                              print('Proceeding with selected quantities: $selectedQuantity');
                                              Navigator.pop(context); // Close the dialog
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal.shade100,
                                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Proceed to Checkout',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              '⚠️ To order multiple items, add them to the cart and check out later.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.red.shade600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5, // Shadow effect
                            ),
                            icon: Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: Text(
                              '  Purchase  ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildRelatedProducts(category,productName),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

