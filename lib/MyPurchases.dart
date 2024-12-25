import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyPurchases extends StatefulWidget {
  @override
  _MyPurchasesState createState() => _MyPurchasesState();
}

class _MyPurchasesState extends State<MyPurchases> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String currentUserId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],  // Set the background color to a light teal
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ), // Set the AppBar to a teal color
        title: Text(
          '            My Purchases',
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold), // White text on the teal background
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.production_quantity_limits, color: Colors.white),  // Optional icon for My Products
              text: 'My Products',
            ),
            Tab(
              icon: Icon(Icons.pending_actions, color: Colors.white),  // Optional icon for Pending Orders
              text: 'Pending Orders',
            ),
          ],
          indicatorColor: Colors.white,  // White indicator color
          indicatorWeight: 3.0,  // Adjust thickness of the indicator
          labelColor: Colors.white,  // Color for the text of the active tab
          unselectedLabelColor: Colors.white.withOpacity(0.7),  // Color for the text of the inactive tab
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,  // Bold text for the active tab
            fontSize: 16.0,  // Font size for the active tab
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,  // Normal weight for inactive tabs
            fontSize: 14.0,  // Font size for inactive tabs
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList('done'), // My Products tab
          _buildProductList('Confirmed'), // Pending Orders tab
        ],
      ),
    );
  }

  // Method to build the list of products based on the order status
  Widget _buildProductList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,  // Icon representing empty cart or no orders
                  size: 80.0,  // Set the icon size
                  color: Colors.teal[300],  // Soft teal color for the icon
                ),
                SizedBox(height: 20),  // Space between icon and text
                Text(
                  'No orders found!',
                  style: TextStyle(
                    fontSize: 24.0,  // Large font size for visibility
                    fontWeight: FontWeight.bold,  // Make the text bold
                    color: Colors.teal[700],  // Teal color for the text
                  ),
                ),
                SizedBox(height: 10),  // Space between the message and the button
                Text(
                  'It looks like you don\'t have any orders yet.\nTry browsing our products!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,  // Smaller font size for the subtext
                    color: Colors.teal[500],  // Lighter teal for the description
                  ),
                ),
                SizedBox(height: 20),  // Space before the button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Browse Products',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,  // Button color
                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),  // Button padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),  // Rounded button corners
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;
        Map<String, Map<int, int>> consolidatedOrders = {}; // Map to hold consolidated data

        // Consolidate orders based on productId and selectedSize
        for (var order in orders) {
          var productId = order['productId']; // Assuming 'productId' exists
          var selectedSize = Map<int, int>.from(
            order['selectedSize']?.map((key, value) => MapEntry(int.parse(key), value)) ??
                {},
          ); // Assuming 'selectedSize' is a Map<String, dynamic>

          // For each order, consolidate the selected sizes and quantities
          if (!consolidatedOrders.containsKey(productId)) {
            consolidatedOrders[productId] = selectedSize;
          } else {
            // If the productId is already in the map, consolidate the sizes and quantities
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

        // List view for displaying the consolidated orders
        return ListView.builder(
          itemCount: consolidatedOrders.keys.length,
          itemBuilder: (context, index) {
            var productId = consolidatedOrders.keys.elementAt(index);
            var sizeQuantities = consolidatedOrders[productId]!;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .get(),
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
                var imageUrlBase64 = product['imageUrl']; // Assuming 'imageUrl' contains the base64 string
                var productname = product['name'];
                // Convert the base64 string to a Uint8List
                var imageBytes = base64Decode(imageUrlBase64);

                // List of size widgets
                List<Widget> sizeWidgets = [];
                sizeQuantities.forEach((size, quantity) {
                  sizeWidgets.add(
                    Text('Size: $size, Quantity: $quantity',
                        style: TextStyle(color: Colors.teal[700])),
                  );
                });

                return Card(
                  color: Colors.teal[100],
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: Container(
                      height: 120.0,  // Set the height of the image
                      width: 90.0,   // Set the width of the image
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10), // Rounded corners with a 10px radius
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), // Subtle shadow for depth
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2), // Shadow direction
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),  // Rounded corners inside the image
                        child: Image.memory(
                          imageBytes, // Display the image from base64
                          fit: BoxFit.cover, // Ensure the image scales properly
                        ),
                      ),
                    ),
                    title: Text(
                      'Name : $productname',
                      style: TextStyle(color: Colors.teal[800]),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...sizeWidgets, // Display all consolidated sizes and quantities
                      ],
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
}
