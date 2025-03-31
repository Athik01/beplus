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
import 'package:google_fonts/google_fonts.dart';
import 'AddBills.dart';
import 'AddNewCreditScreen.dart';
import 'AddProducts.dart';
import 'BuildCarousel.dart';
import 'CustomerBills.dart';
import 'MyPurchases.dart';
import 'ProductDetailsPage.dart';
import 'analysis.dart';
import 'hos.dart';
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
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Hi ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.normal, // Normal weight for "Hi"
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: '${userData?.displayName ?? 'User'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold, // Bold weight for the name
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade900, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.4),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
          ),
        ],
      ),
      drawer: _buildCustomDrawer(),
      body: _buildTabbedView(context,userId),
    );
  }

  // Helper function to capitalize the first letter
  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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
          // Filter the products based on visibility
          List products = (snapshot.data as List).where((product) {
            List<dynamic> visibility = product['visibility'] ?? [];
            return visibility.contains(userId); // Only include visible products
          }).toList();

          if (products.isEmpty) {
            return Center(child: Text('No visible products.'));
          }

          return Scaffold(
            body: Stack(
              children: [
                // Background image with white fade effect
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/assets/shop.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.7),
                          Colors.white.withOpacity(0.3),
                        ],
                        stops: [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                // Foreground grid of products
                GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two products per row
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65, // Adjusted for better card height
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var product = products[index];
                    final productId = product['id'];
                    // Convert product name to have the first letter in caps
                    final productName = capitalize(product['name'] ?? 'Unnamed Product');
                    final imageUrl = product['imageUrl'];

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderPage(productId: productId),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Product Image with Hero animation
                            Hero(
                              tag: 'productImage-$productId',
                              child: imageUrl != null
                                  ? Image.memory(
                                base64Decode(imageUrl),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Text(
                                    'No Image',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Gradient overlay for product name readability
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Text(
                                  productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black38,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
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
        final int count = orders.length;
        int test = 0;
        if (orders.isEmpty) {
          return const Center(child: Text('No matching orders found.'));
        }
        int doneCount = 0;
        orders.forEach((order) {
          if (order['status'] == "done") {
            doneCount++;
          }
        });
        return doneCount == orders.length
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 100,
                color: Colors.tealAccent,
              ),
              SizedBox(height: 20),
              Text(
                'No Orders in the Queue!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'You haven’t placed any orders yet.\nStart shopping and place new orders 😉!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.teal.shade500,
                ),
              ),
              SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyPurchases()),
                  );
                },
                icon: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
                label: Text(
                  'My Purchases!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ) : // Add other UI for non-empty orders here
        ListView.builder(
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

                                  // Cancel Order Button if not done or confirmed
                                  if (status == 'Not Confirmed' && status != 'Confirmed' || status != 'done')
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
                                ],
                              ),
                            ),
                          );
                        }
                    );
                  },
                  child: Visibility(
                      visible: status != 'done',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade900, Colors.teal.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      widget.user?.photoURL ??
                          'https://www.w3schools.com/howto/img_avatar.png',
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
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 4),
                      ],
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
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.currency_rupee, 'My Purchases', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyPurchases()),
                    );
                  }),
                  _buildCustomDivider(),
                  _buildDrawerItem(Icons.shopping_bag, 'My Bills', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ViewCustomerBills(customerId: userId)),
                    );
                  }),
                  _buildCustomDivider(),
                  _buildDrawerItem(Icons.calculate_sharp, 'Analysis', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnalysisScreen()),
                    );
                  }),
                  _buildCustomDivider(),
                  _buildDrawerItem(
                      Icons.shopping_bag_outlined, 'Purchase Bills', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AddCustomerBills(customerId: userId)),
                    );
                  }),
                  _buildCustomDivider(),
                  _buildDrawerItem(Icons.shopping_cart_rounded,
                      'History of Purchase', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HOS(customerId: userId)),
                        );
                      }),
                  _buildCustomDivider(),
                  _buildDrawerItem(Icons.logout, 'Logout', () async {
                    try {
                      await FirebaseAuth.instance.signOut();
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
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDivider() {
    return Divider(
      color: Colors.grey.shade300,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }


  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.teal.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.teal.shade50, // Light teal background
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.teal.shade700,
                  size: 28,
                ),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: Colors.teal.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.teal.shade400,
              ),
            ),
          ),
        ),
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
              //_buildWelcomeText(),
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
              BuildCarousel(),
              SizedBox(height: 10),
              StockAlert(userId),
              _buildCategoryCards(),
              _buildFavoriteProducts(),
              RecentPurchases(userId),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("cust_products")
                    .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid) // Filter by userId
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🎨 Add an illustration or icon
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 15),

                            // 📝 Styled message
                            Text(
                              "No products available",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 🏷️ Subtext for better user engagement
                            Text(
                              "Start adding your products to manage inventory efficiently!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  }

                  // 📌 Classify products dynamically
                  List<DocumentSnapshot> perishableProducts = [];
                  List<DocumentSnapshot> sizeVariantProducts = [];
                  List<DocumentSnapshot> regularProducts = [];

                  for (var doc in snapshot.data!.docs) {
                    var product = doc.data() as Map<String, dynamic>;
                    bool hasExpiryDate = product["hasExpiryDate"] ?? false;
                    bool hasSizeVariants = product["hasSizeVariants"] ?? false;

                    if (hasExpiryDate) {
                      perishableProducts.add(doc);
                    } else if (hasSizeVariants) {
                      sizeVariantProducts.add(doc);
                    } else {
                      regularProducts.add(doc);
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (perishableProducts.isNotEmpty)
                        productCategorySection(
                            context, "Perishable Products", perishableProducts),
                      if (sizeVariantProducts.isNotEmpty)
                        productCategorySection(
                            context, "Size-Variant Products", sizeVariantProducts),
                      if (regularProducts.isNotEmpty)
                        productCategorySection(context, "Regular Products", regularProducts),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget productCategorySection(BuildContext context,String title, List<DocumentSnapshot> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: products.map((doc) {
                var product = doc.data() as Map<String, dynamic>;
                product["id"] = doc.id;
                return productCard(context,product);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 🖼 PRODUCT CARD UI
  Widget productCard(BuildContext context, Map<String, dynamic> product) {
    Uint8List? imageBytes;
    if (product["imageBase64"] != null) {
      imageBytes = base64Decode(product["imageBase64"]);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: imageBytes != null
                  ? Image.memory(imageBytes, height: 120, width: 160, fit: BoxFit.cover)
                  : Image.asset("lib/assets/broken.jpg", height: 120, width: 160, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (product["hasSizeVariants"] ?? false)
                    Text("Multiple Sizes Available", style: const TextStyle(color: Colors.grey)),
                  if (!(product["hasSizeVariants"] ?? false))
                    Text("Rs. ${product["price"]}", style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget RecentPurchases(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'done')
          .orderBy('orderDate', descending: true)
          .limit(3)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}', style: GoogleFonts.montserrat()));
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No recent purchases found!',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          );
        }

        final recentOrders = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'My Recent Purchases 🛍️',
                style: GoogleFonts.montserrat(
                  color: Colors.blueGrey.shade900,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height - 150,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: recentOrders.length,
                itemBuilder: (context, index) {
                  var order = recentOrders[index];
                  var productId = order['productId'];
                  var orderDate = (order['orderDate'] as Timestamp).toDate();
                  var formattedDate =
                      "${orderDate.day}-${orderDate.month}-${orderDate.year}";

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('products')
                        .doc(productId)
                        .get(),
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingCard();
                      }

                      if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                        return _buildErrorCard();
                      }

                      var product = productSnapshot.data!;
                      var productName = product['name'];
                      var imageBase64 = product['imageUrl'] ?? '';

                      Uint8List? imageBytes;
                      if (imageBase64.isNotEmpty) {
                        try {
                          imageBytes = base64Decode(imageBase64);
                        } catch (_) {
                          imageBytes = null;
                        }
                      }

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.blueGrey.withOpacity(0.3),
                        color: Colors.transparent, // make card transparent to show background
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: AssetImage('lib/assets/back2.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Inner container to reveal border image
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                productName,
                                style: GoogleFonts.montserrat(
                                  color: Colors.blueGrey.shade900,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Purchased on: $formattedDate',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: imageBytes != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  imageBytes,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        title: Container(
          height: 14,
          width: 100,
          color: Colors.grey[300],
        ),
        subtitle: Container(
          height: 12,
          width: 80,
          color: Colors.grey[200],
        ),
        trailing: Container(
          width: 60,
          height: 60,
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        title: Text(
          'Product not found',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }



  Widget StockAlert(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: userId).where('status', isEqualTo: 'done').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No orders found!'));
        }

        final orders = snapshot.data!.docs;
        Map<String, Map<int, int>> consolidatedOrders = {}; // Map to hold consolidated data

        // Consolidate orders based on productId and selectedSize
        for (var order in orders) {
          var productId = order['productId'];
          var selectedSize = Map<int, int>.from(
            order['selectedSize']?.map((key, value) => MapEntry(int.parse(key), value)) ?? {},
          );
          if (!consolidatedOrders.containsKey(productId)) {
            consolidatedOrders[productId] = selectedSize;
          } else {
            selectedSize.forEach((size, quantity) {
              if (consolidatedOrders[productId]!.containsKey(size)) {
                consolidatedOrders[productId]![size] =
                    consolidatedOrders[productId]![size]! + quantity;
              } else {
                consolidatedOrders[productId]![size] = quantity;
              }
            });
          }
        }
        List<Map<String, dynamic>> lowStockProducts = [];
        consolidatedOrders.forEach((productId, sizeQuantities) {
          sizeQuantities.forEach((size, quantity) {
            if (quantity <= 0) {
              lowStockProducts.add({'productId': productId, 'size': size, 'quantity': quantity});
            }
          });
        });

        if (lowStockProducts.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Low Stock Alert 🚨',
                  style: TextStyle(
                    color: Colors.red,
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
                  maxHeight: MediaQuery.of(context).size.height - 150,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: lowStockProducts.length,
                  itemBuilder: (context, index) {
                    var lowStockProduct = lowStockProducts[index];
                    var productId = lowStockProduct['productId'];
                    var size = lowStockProduct['size'];
                    var quantity = lowStockProduct['quantity'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                      builder: (context, productSnapshot) {
                        if (productSnapshot.connectionState == ConnectionState.waiting) {
                          return Card(
                            color: Colors.teal[100],
                            margin: EdgeInsets.all(10),
                            child: ListTile(
                              title: Text('Loading product details...'),
                            ),
                          );
                        }

                        if (!productSnapshot.hasData) {
                          return Card(
                            color: Colors.teal[100],
                            margin: EdgeInsets.all(10),
                            child: ListTile(
                              title: Text('Product not found'),
                            ),
                          );
                        }

                        var product = productSnapshot.data!;
                        var productName = product['name'];
                        var imageBase64 = product['imageUrl'] ?? '';  // Get the base64 string for the image

                        Uint8List? imageBytes;
                        if (imageBase64.isNotEmpty) {
                          try {
                            imageBytes = base64Decode(imageBase64);  // Decode the base64 string
                          } catch (_) {
                            imageBytes = null;
                          }
                        }

                        return Card(
                          color: Colors.red[100],
                          margin: EdgeInsets.all(10),
                          child: ListTile(
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Product Name: $productName', style: TextStyle(color: Colors.red)),
                                      Text('Size: $size', style: TextStyle(color: Colors.red)),
                                      Text('Quantity: $quantity', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                                if (imageBytes != null)  // Check if the imageBytes are available
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        imageBytes,
                                        width: 60,  // Set width for the image
                                        height: 60,  // Set height for the image
                                        fit: BoxFit.cover,
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
          );
        }
        return Container();
      },
    );
  }

  Widget _buildFavoriteProducts() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('products').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.montserrat()));
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No products available', style: GoogleFonts.montserrat()));
        }

        final likedProducts = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final likes = data['likes'] as Map<String, dynamic>? ?? {};
          final visibility = data['visibility'] as List<dynamic>? ?? [];

          final isLiked = likes[userId] == true;
          final isVisible = visibility.contains(userId);

          return isLiked && isVisible;
        }).toList();

        // If likedProducts is empty, return an empty widget
        if (likedProducts.isEmpty) {
          return Container();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'My Wishlist! ❤️',
                style: GoogleFonts.montserrat(
                  color: Colors.blueGrey.shade900,
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
                maxHeight: MediaQuery.of(context).size.height - 150,
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
                itemCount: likedProducts.length,
                itemBuilder: (context, index) {
                  final product = likedProducts[index].data() as Map<String, dynamic>? ?? {};
                  final productName = product['name'] ?? 'Unnamed';
                  final imageBase64 = product['imageUrl'] ?? '';

                  Uint8List? imageBytes;
                  if (imageBase64.isNotEmpty) {
                    try {
                      imageBytes = base64Decode(imageBase64);
                    } catch (_) {
                      imageBytes = null;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderPage(productId: likedProducts[index].id),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Colors.blueGrey.withOpacity(0.3),
                      color: Colors.transparent, // Make card transparent to show the background border.
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage('lib/assets/back2.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Inner container with margin reveals the border image
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Product image with rounded top corners
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  child: imageBytes != null
                                      ? Image.memory(
                                    imageBytes,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  )
                                      : Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              // Product name text with gradient background
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.blueGrey.shade100],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Text(
                                  productName,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.blueGrey.shade900,
                                    fontSize: 18,
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
  Widget _buildCategoryCards() {
    return FutureBuilder<QuerySnapshot>(
      future: _categoriesCollection.get(),
      builder: (context, categoriesSnapshot) {
        if (categoriesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (categoriesSnapshot.hasError) {
          return Center(
            child: Text('Error: ${categoriesSnapshot.error}', style: GoogleFonts.montserrat()),
          );
        }
        if (categoriesSnapshot.data == null || categoriesSnapshot.data!.docs.isEmpty) {
          return Center(child: Text('', style: GoogleFonts.montserrat()));
        }

        // Get all follow requests for the current user
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('requests')
              .where('customerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, requestsSnapshot) {
            if (requestsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (requestsSnapshot.hasError) {
              return Center(
                child: Text('Error: ${requestsSnapshot.error}', style: GoogleFonts.montserrat()),
              );
            }

            // Build list of confirmed owner IDs from the requests
            final confirmedOwnerIds = requestsSnapshot.data!.docs
                .where((doc) => doc['status'] == 'Confirmed')
                .map((doc) => doc['ownerId'])
                .toList();

            // Filter out categories (shops) that already have a confirmed request
            final filteredCategories = categoriesSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ownerId = data['userId'] ?? '';
              return !confirmedOwnerIds.contains(ownerId);
            }).toList();

            if (filteredCategories.isEmpty) {
              return Center(child: Text('', style: GoogleFonts.montserrat()));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: "New Shops"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Text(
                      'New Shops',
                      style: GoogleFonts.montserrat(
                        color: Colors.blueGrey.shade900,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.blueGrey.withOpacity(0.2),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Grid of shops
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final categoryDoc = filteredCategories[index];
                        final categoryData = categoryDoc.data() as Map<String, dynamic>;
                        // ownerId is stored in the category document under "userId"
                        final ownerId = categoryData['userId'] ?? '';

                        // Fetch the owner details from the users collection
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (userSnapshot.hasError) {
                              return Center(
                                child: Text('Error: ${userSnapshot.error}', style: GoogleFonts.montserrat()),
                              );
                            }
                            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                              return Center(
                                child: Text('Owner not found', style: GoogleFonts.montserrat()),
                              );
                            }

                            // Using the owner's details for theme consistency (e.g. name)
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            final userName = userData['name'] ?? 'Unknown User';
                            final ownerImageUrl = userData['photoURL'] ?? '';

                            // Determine which image to display for the owner (fallback image)
                            Widget ownerImage;
                            if (ownerImageUrl.startsWith('https://')) {
                              ownerImage = Image.network(ownerImageUrl, fit: BoxFit.cover);
                            } else if (ownerImageUrl.isNotEmpty) {
                              try {
                                final imageBytes = base64Decode(ownerImageUrl);
                                ownerImage = Image.memory(imageBytes, fit: BoxFit.cover);
                              } catch (e) {
                                ownerImage = Image.asset('assets/default_image.png', fit: BoxFit.cover);
                              }
                            } else {
                              ownerImage = Image.asset('assets/default_image.png', fit: BoxFit.cover);
                            }

                            // Check for an existing follow request (status: Not Confirmed) for this owner
                            QueryDocumentSnapshot? requestForOwner;
                            try {
                              requestForOwner = requestsSnapshot.data!.docs.firstWhere(
                                    (doc) => doc['ownerId'] == ownerId && doc['status'] == 'Not Confirmed',
                              );
                            } catch (e) {
                              requestForOwner = null;
                            }
                            final bool isRequested = requestForOwner != null;
                            final String followButtonText = isRequested ? 'Requested' : 'Follow';

                            return InkWell(
                              onTap: () {
                                // When the category card is pressed,
                                // show a details dialog with category details and related products.
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          image: const DecorationImage(
                                            image: AssetImage('lib/assets/back2.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.98),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: SingleChildScrollView(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  // Display category details from the category document.
                                                  Text(
                                                    categoryData['name'] ?? 'No Name',
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blueGrey.shade900,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Category image (base64 or URL)
                                                  Builder(
                                                    builder: (context) {
                                                      final catImage = categoryData['image'] ?? '';
                                                      if (catImage.startsWith('https://')) {
                                                        return Image.network(catImage,
                                                            height: 150, fit: BoxFit.cover);
                                                      } else if (catImage.isNotEmpty) {
                                                        try {
                                                          final imageBytes = base64Decode(catImage);
                                                          return Image.memory(imageBytes,
                                                              height: 150, fit: BoxFit.cover);
                                                        } catch (e) {
                                                          return Image.asset('assets/default_image.png',
                                                              height: 150, fit: BoxFit.cover);
                                                        }
                                                      } else {
                                                        return Image.asset('assets/default_image.png',
                                                            height: 150, fit: BoxFit.cover);
                                                      }
                                                    },
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    categoryData['description'] ?? 'No Description available.',
                                                    style: GoogleFonts.montserrat(fontSize: 16),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  // Fetch and display products for this category
                                                  FutureBuilder<QuerySnapshot>(
                                                    future: FirebaseFirestore.instance
                                                        .collection('products')
                                                        .where('ownerId', isEqualTo: ownerId)
                                                        .where('category', isEqualTo: categoryData['name'])
                                                        .get(),
                                                    builder: (context, productsSnapshot) {
                                                      if (productsSnapshot.connectionState == ConnectionState.waiting) {
                                                        return const Center(child: CircularProgressIndicator());
                                                      }
                                                      if (productsSnapshot.hasError) {
                                                        return Center(
                                                          child: Text('Error: ${productsSnapshot.error}', style: GoogleFonts.montserrat()),
                                                        );
                                                      }
                                                      if (productsSnapshot.data == null || productsSnapshot.data!.docs.isEmpty) {
                                                        return Center(
                                                          child: Text('No products found', style: GoogleFonts.montserrat()),
                                                        );
                                                      }
                                                      return Column(
                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                        children: productsSnapshot.data!.docs.map((prodDoc) {
                                                          final prodData = prodDoc.data() as Map<String, dynamic>;
                                                          final prodName = prodData['name'] ?? 'No Name';
                                                          final prodImageUrl = prodData['imageUrl'] ?? '';
                                                          Widget prodImage;
                                                          if (prodImageUrl.startsWith('https://')) {
                                                            prodImage = Image.network(prodImageUrl, fit: BoxFit.cover, height: 100);
                                                          } else if (prodImageUrl.isNotEmpty) {
                                                            try {
                                                              final imageBytes = base64Decode(prodImageUrl);
                                                              prodImage = Image.memory(imageBytes, fit: BoxFit.cover, height: 100);
                                                            } catch (e) {
                                                              prodImage = Image.asset('assets/default_image.png', fit: BoxFit.cover, height: 100);
                                                            }
                                                          } else {
                                                            prodImage = Image.asset('assets/default_image.png', fit: BoxFit.cover, height: 100);
                                                          }
                                                          return Card(
                                                            margin: const EdgeInsets.symmetric(vertical: 8),
                                                            child: ListTile(
                                                              leading: SizedBox(width: 50, height: 50, child: prodImage),
                                                              title: Text(prodName, style: GoogleFonts.montserrat(fontSize: 14)),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 8,
                                shadowColor: Colors.blueGrey.withOpacity(0.3),
                                color: Colors.transparent, // Make Card transparent to show the background.
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    image: const DecorationImage(
                                      image: AssetImage('lib/assets/back2.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Inner Container with margin reveals the border image.
                                  child: Container(
                                    margin: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Owner image with rounded top corners (fallback or theme image)
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                            child: ownerImage,
                                          ),
                                        ),
                                        // Owner name and follow button
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                            gradient: LinearGradient(
                                              colors: [Colors.white, Colors.blueGrey.shade100],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                userName,
                                                style: GoogleFonts.montserrat(
                                                  color: Colors.blueGrey.shade900,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: isRequested
                                                    ? null
                                                    : () async {
                                                  try {
                                                    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                                    if (currentUserId != null) {
                                                      await FirebaseFirestore.instance.collection('requests').add({
                                                        'customerId': currentUserId,
                                                        'ownerId': ownerId,
                                                        'status': 'Not Confirmed',
                                                        'timestamp': FieldValue.serverTimestamp(),
                                                      });
                                                      // Immediately update UI
                                                      setState(() {});
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Follow request sent!',
                                                            style: GoogleFonts.montserrat(),
                                                          ),
                                                          backgroundColor: Colors.blueGrey.shade700,
                                                        ),
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Please log in to send a follow request.',
                                                            style: GoogleFonts.montserrat(),
                                                          ),
                                                          backgroundColor: Colors.red.shade700,
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Error sending request: $e',
                                                          style: GoogleFonts.montserrat(),
                                                        ),
                                                        backgroundColor: Colors.red.shade700,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor: Colors.blueGrey,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                ),
                                                child: Text(
                                                  followButtonText,
                                                  style: GoogleFonts.montserrat(fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
            );
          },
        );
      },
    );
  }



  Widget _buildTabbedView(BuildContext context, String userId) {
    return DefaultTabController(
      length: 5, // Match the number of tabs
      child: Scaffold(
        body: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'lib/assets/back.png',
                fit: BoxFit.cover,
              ),
            ),
            // White fading gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Main Content: TabBarView
            TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                Scaffold(
                  body: _buildBody(),
                  floatingActionButton: FloatingActionButton(
                    backgroundColor: Colors.blueGrey,
                    child: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductPage(),
                        ),
                      );
                    },
                  ),
                ), // Home Tab
                _buildShop(),  // Shop Tab
                Container(),   // Empty container for spacing
                _buildSeller(), // Seller Tab
                _buildBills(),  // Orders Tab
              ],
            ),
          ],
        ),
        bottomNavigationBar: Stack(
          alignment: Alignment.center,
          children: [
            // Bottom Navigation Container
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                child: TabBar(
                  labelColor: Colors.blueGrey,
                  unselectedLabelColor: Colors.grey,
                  indicatorPadding: EdgeInsets.symmetric(horizontal: 20),
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 4.0, color: Colors.blueGrey),
                    insets: EdgeInsets.symmetric(horizontal: 35),
                  ),
                  tabs: [
                    _buildTab(Icons.home),
                    _buildTab(Icons.shopping_cart),
                    SizedBox(width: 60), // Space for Floating Button
                    _buildTab(Icons.store),
                    _buildTab(Icons.receipt),
                  ],
                ),
              ),
            ),
            // Centered Floating Cart Button
            Positioned(
              bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  backgroundColor: Colors.blueGrey,
                  elevation: 0,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartPage(userId: userId),
                      ),
                    );
                  },
                  child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon) {
    return Tab(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueGrey.withOpacity(0.1),
        ),
        child: Icon(icon, size: 26),
      ),
    );
  }


}

