import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:beplus/cart_page.dart';
import 'package:beplus/order_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beplus/profile.dart';
import 'package:beplus/login.dart';
import 'package:beplus/category_details.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:beplus/owner_details.dart';
class HomePage1 extends StatefulWidget {
  final User? user;

  const HomePage1({required this.user});

  @override
  _HomePage1State createState() => _HomePage1State();
}

class _HomePage1State extends State<HomePage1> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _categoriesCollection;
  double profileCompletion = 0.0; // To calculate profile completion percentage
  Map<String, dynamic>? userData;
  late String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    _categoriesCollection = _firestore.collection('categories');
    _fetchUserProfile();
  }
  Future<void> _fetchUserProfile() async {
    try {
      // Get the current user's ID from FirebaseAuth
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('No user is logged in.');
        return;
      }
      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // Use the current user's ID
          .get();
      if (userDoc.exists) {
        // Update state with fetched data and calculate profile completion
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          profileCompletion = _calculateProfileCompletion(userData);
        });
      } else {
        print('User document does not exist!');
      }
    } catch (e) {
      // Handle errors gracefully
      print('Error fetching user profile: $e');
    }
  }
  double _calculateProfileCompletion(Map<String, dynamic>? data) {
    if (data == null) return 0.0;

    List<String> requiredFields = [
      'email',
      'address',
      'gstNumber',
      'mobile',
      'name',
      'state',
      'userType'
    ];

    int filledFields = 0;

    // Check if each field is filled
    for (var field in requiredFields) {
      var value = data[field];

      // Print the value of each field for debugging
      print('Field "$field" value: $value');

      // Check if the value is non-null and non-empty
      if (value != null && value.toString().isNotEmpty) {
        filledFields++;
      } else {
        print('Field "$field" is not filled or invalid.');
      }
    }

    // Return the profile completion percentage
    double profileCompletion = (filledFields / requiredFields.length) * 100;


    print('Profile Completion: $profileCompletion%');

    return profileCompletion;
  }


  @override
  Widget build(BuildContext context) {
    // Get the current user data from FirebaseAuth
    User? userData = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${userData?.displayName ?? 'User'}!',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildCustomDrawer(),
      body: _buildTabbedView(),
    );
  }

  Widget _buildShop() {
    return FutureBuilder(
      future: _fetchProducts(), // Fetch the products
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(child: Text('No products found.'));
        } else {
          List products = snapshot.data as List;

          return Scaffold(
            body: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two products per row
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7, // Reduced the ratio to increase card height
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                var product = products[index];
                final productId = product['id'];
                List<dynamic> visibility = product['visibility'] ?? [];
                bool isVisible = visibility.contains(userId); // Check for visibility
                if (!isVisible) {
                  return SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderPage(productId: productId),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.teal.shade300, // Teal combo for the card background
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: product['imageUrl'] != null
                              ? Image.memory(
                            base64Decode(product['imageUrl']),
                            width: double.infinity,
                            height: 205, // Fixed height for uniformity
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: double.infinity,
                            height: 140,
                            color: Colors.grey[300],
                            child: Center(
                              child: Text(
                                'No Image',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Centers the content horizontally
                          crossAxisAlignment: CrossAxisAlignment.center, // Centers the content vertically
                          children: [
                            Icon(Icons.shopping_cart, color: Colors.white),
                            const SizedBox(width: 8), // Adds space between the icon and text
                            Text(
                              product['name'] ?? 'Unnamed Product',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }


  Future<List> _fetchProducts() async {
    // Get the current user's ID (this depends on your authentication setup)
    String currentUserId = FirebaseAuth.instance.currentUser!.uid; // Replace this with actual current user ID retrieval logic
    print("Current User ID: $currentUserId");

    // Step 1: Fetch requests where customerId matches the current user's ID and status is confirmed
    QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('customerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'Confirmed')
        .get();

    if (requestSnapshot.docs.isEmpty) {
      print("No matching requests found.");
      return []; // No matching requests found
    }

    List productList = [];
    print("Requests found: ${requestSnapshot.docs.length}");

    for (var request in requestSnapshot.docs) {
      String ownerId = request['ownerId'];


      // Step 2: Fetch categories where ownerId matches
      QuerySnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      // Step 3: Fetch products where ownerId matches the userId of the product
      QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: ownerId)
          .get();

      if (productSnapshot.docs.isEmpty) {

      } else {
        for (var productDoc in productSnapshot.docs) {
          var productData = productDoc.data() as Map<String, dynamic>?;

          // Check if productData is not null
          if (productData != null) {
            productData['id'] = productDoc.id; // Add the document ID to productData
            productList.add(productData);
          } else {
            print("Product data is null for document ID: ${productDoc.id}");
          }
        }
      }
    }
    return productList;
  }


  Widget _buildSeller() {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('requests')
          .where('customerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No matching requests found.',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        // Display the ownerIds in cards
        final requestDocs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: requestDocs.length,
          itemBuilder: (context, index) {
            final ownerId = requestDocs[index]['ownerId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading owner details',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Owner details not found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final ownerData = snapshot.data!.data() as Map<String, dynamic>;
                final name = ownerData['name'] ?? 'N/A';
                final shopName = ownerData['shopName'] ?? 'N/A';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerDetailsPage(ownerId: ownerId),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.teal,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.store_mall_directory,
                                      color: Colors.grey[700],
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        shopName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  Widget _buildBills() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading orders.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // Offset for the shadow
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No orders found!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '                                                               ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final orders = snapshot.data!.docs
            .where((order) => order['userId'] == currentUserId)
            .toList();

        if (orders.isEmpty) {
          return const Center(child: Text('No matching orders found.'));
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderId = orders[index].id;
            final productId = order['productId'];
            final status = order['status'];
            final amount = order['totalAmount'];
            final orderDate = order['orderDate'];
            final selectedSize = order['selectedSize'];

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('products').doc(productId).snapshots(),
              builder: (context, productSnapshot) {
                if (productSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productSnapshot.hasError) {
                  return const Center(child: Text('Error loading product details.'));
                }

                if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                  return const Center(child: Text('Product not found.'));
                }
                final product = productSnapshot.data!;
                final productName = product['name'];
                final base64Image = product['imageUrl'];

                // Decode the base64 image string
                final imageBytes = base64.decode(base64Image);
                final image = Image.memory(imageBytes);

                return GestureDetector(
                  onTap: () {
                    // Show the dialog when the card is clicked
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100, // Light background color for emphasis
                              borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between the title and close icon
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.teal,
                                      size: 24.0,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      'Product Details',
                                      style: TextStyle(
                                        fontSize: 20, // Larger font size for emphasis
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800, // Darker text color for contrast
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.red, // Red color for close icon
                                    size: 24.0, // Adjust size as needed
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close the dialog when clicked
                                  },
                                ),
                              ],
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image with rounded border for a more polished look
                                ClipOval(
                                  child: SizedBox(
                                    height: 100, // Adjust the image height
                                    width: 100, // Adjust the image width for a smaller size
                                    child: image,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Product Name with increased emphasis
                                Text(
                                  'Product Name: $productName',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800, // Darker color for emphasis
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600], // Slightly darker grey for better readability
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Amount: ₹${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Order Date: ${DateFormat('yMMMd').format(orderDate.toDate())}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600], // Similar color as status for consistency
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Selected Sizes:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800, // Matches the product name for visual cohesion
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8.0, // Space between chips
                                  runSpacing: 4.0, // Space between lines of chips
                                  children: selectedSize.entries.map<Widget>((entry) {
                                    return Chip(
                                      label: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          'Size: ${entry.key} - Quantity ${entry.value}',
                                          style: TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                      backgroundColor: Colors.teal.shade700, // Slightly darker teal for better contrast
                                      elevation: 2, // Adds subtle shadow for depth
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0), // Rounded corners for a modern look
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                // Conditional cancel button display based on status

                                if (status == 'Not Confirmed' || status != 'Confirmed') // Adjust the condition as needed
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0), // Padding around the button
                                      child: SizedBox(
                                        width: double.infinity, // Make the button span the full width
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              // Replace 'orderId' with the actual variable holding the order ID
                                              await FirebaseFirestore.instance
                                                  .collection('orders')
                                                  .doc(orderId)
                                                  .delete();

                                              // Show a success message
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: Colors.teal, // Success color
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.check_circle, // Success icon
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 8), // Spacing between icon and text
                                                      Expanded(
                                                        child: Text(
                                                          'Order Cancelled',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  duration: Duration(seconds: 3), // Display duration
                                                  behavior: SnackBarBehavior.floating, // Floating snackbar
                                                ),
                                              );
                                              Navigator.of(context).pop();
                                            } catch (e) {
                                              // Show an error message if something goes wrong
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: Colors.red, // Error color
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error, // Error icon
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 8), // Spacing between icon and text
                                                      Expanded(
                                                        child: Text(
                                                          'Error deleting order: $e',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  duration: Duration(seconds: 3), // Display duration
                                                  behavior: SnackBarBehavior.floating, // Floating snackbar
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red, // Button color
                                            padding: EdgeInsets.symmetric(vertical: 15.0), // Padding inside the button
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center, // Center content
                                            children: [
                                              Icon(
                                                Icons.delete_rounded, // Icon for the button
                                                color: Colors.white, // Icon color
                                                size: 20, // Icon size
                                              ),
                                              SizedBox(width: 8), // Spacing between icon and text
                                              Text(
                                                'Cancel Order',
                                                style: TextStyle(
                                                  fontSize: 15, // Text size
                                                  fontWeight: FontWeight.bold, // Bold text
                                                  color: Colors.white, // Text color
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (status == 'Confirmed' || status != 'Not Confirmed')
                                  Center(
                                    child: Chip(
                                      backgroundColor: Colors.teal[50], // Light teal background
                                      avatar: CircleAvatar(
                                        backgroundColor: Colors.green, // Checked circle color
                                        child: Icon(
                                          Icons.check_circle, // Checked icon
                                          color: Colors.white,
                                        ),
                                      ),
                                      label: Text(
                                        'Order Placed!',
                                        style: TextStyle(
                                          color: Colors.teal, // White text
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16), // Optional: round corners
                                        side: BorderSide(
                                          color: Colors.teal.shade800, // Dark border color
                                          width: 1,
                                        ),
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
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              height: 100, // Adjust the image height
                              width: 100, // Adjust the image width for a smaller size
                              child: image,
                            ),
                          ),
                          const SizedBox(width: 16), // Space between the image and details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                              children: [
                                Text(
                                  '$productName',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      status == 'Confirmed' ? 'Confirmed' : '$status',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: status == 'Confirmed' ? Colors.teal : Colors.grey,
                                      ),
                                    ),
                                    if (status == 'Confirmed')
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4.0),
                                        child: Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }



  Widget _buildCustomDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.teal, // Teal header
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      widget.user?.photoURL ?? 'https://www.w3schools.com/howto/img_avatar.png',
                    ),
                    backgroundColor: Colors.white,
                    child: widget.user?.photoURL == null
                        ? Icon(Icons.person, size: 50, color: Colors.teal)
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.user?.displayName ?? 'User Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white, // White body background
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.person, 'Profile', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  }),
                  Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildDrawerItem(
                    Icons.logout,
                    'Logout',
                        () async {
                      try {
                        // Sign out from Firebase
                        await FirebaseAuth.instance.signOut();
                        // Initialize GoogleSignIn
                        final GoogleSignIn googleSignIn = GoogleSignIn();
                        if (await googleSignIn.isSignedIn()) {
                          await googleSignIn.signOut();
                          await googleSignIn.disconnect();
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginApp()),
                        );
                      } catch (e) {
                        print('Error during logout: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.black, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        hoverColor: Colors.teal.shade100,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black45),
      ),
    );
  }


  Widget _buildBody() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        SingleChildScrollView(
          child: Column(
            children: [
              _buildWelcomeText(),
              if (profileCompletion < 100)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          Text(
                            'Profile Completion: ${profileCompletion.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: profileCompletion / 100,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            color: Colors.teal,
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              _buildCategoryCards(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.waving_hand, color: Colors.black, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hello, ${widget.user?.displayName ?? 'Guest'}!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.4),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Discover and book amazing experiences with just a tap.',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    return FutureBuilder<QuerySnapshot>(
      future: _categoriesCollection.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No categories available'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'New Hot Selling Products🔥',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height - 150, // Adjust height
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.85,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var category = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String categoryName = category['name'] ?? 'Unnamed';
                  String imageBase64 = category['image'] ?? '';

                  Uint8List? imageBytes;
                  if (imageBase64.isNotEmpty) {
                    try {
                      imageBytes = base64Decode(imageBase64);
                    } catch (e) {
                      imageBytes = null;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryDetailsPage(
                            categoryId: snapshot.data!.docs[index].id,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 10,
                      shadowColor: Colors.teal.withOpacity(0.3),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: imageBytes != null
                                  ? Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                                  : Container(
                                color: Colors.grey.shade300,
                                child: Image.network(
                                  'https://www.w3schools.com/w3images/lights.jpg', // Default image
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                              gradient: LinearGradient(
                                colors: [Colors.white54, Colors.teal.shade300],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                color: Colors.teal.shade900,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildTabbedView() {
    return DefaultTabController(
      length: 4, // Number of tabs
      child: Scaffold(
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildBody(), // Home Tab
            _buildShop(), // Shop Tab
            _buildSeller(), // Seller Tab
            _buildBills(), // Bills Tab
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.teal, // Teal background for TabBar
          child: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'Shop'),
              Tab(icon: Icon(Icons.store), text: 'Seller'),
              Tab(icon: Icon(Icons.receipt), text: 'Bills'),
            ],
          ),
        ),
      ),
    );
  }
}

