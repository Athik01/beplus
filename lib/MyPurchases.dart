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
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'My Purchases',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: [Colors.white, Colors.grey.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.production_quantity_limits),
              text: 'My Products',
            ),
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pending Orders',
            ),
          ],
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14.0,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // First Tab: Use a Stack with background image and white fading overlay
          Stack(
            children: [
              // Background image
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('lib/assets/myproducts.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // White fading overlay with multiple stops for gradual fade
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,                        // full white at the top
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.5),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
              // Your product list content
              _buildProductList('done'),
            ],
          ),
          // Second Tab: Use a simple container with a light teal background
          Container(
            color: Colors.teal[50],
            child: _buildProductList('Confirmed'),
          ),
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
                  Icons.shopping_cart_outlined,
                  size: 80.0,
                  color: Colors.teal[300],
                ),
                SizedBox(height: 20),
                Text(
                  'No orders found!',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'It looks like you don\'t have any orders yet.\nTry browsing our products!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.teal[500],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Browse Products', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;
        Map<String, Map<int, int>> consolidatedOrders = {}; // Consolidated orders map

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
                consolidatedOrders[productId]![size] = consolidatedOrders[productId]![size]! + quantity;
              } else {
                consolidatedOrders[productId]![size] = quantity;
              }
            });
          }
        }

        return ListView.builder(
          itemCount: consolidatedOrders.keys.length,
          itemBuilder: (context, index) {
            var productId = consolidatedOrders.keys.elementAt(index);
            var sizeQuantities = consolidatedOrders[productId]!;

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
                var imageUrlBase64 = product['imageUrl'];
                var productname = product['name'];
                var imageBytes = base64Decode(imageUrlBase64);

                // Build size & quantity widgets
                List<Widget> sizeWidgets = [];
                sizeQuantities.forEach((size, quantity) {
                  sizeWidgets.add(
                    Text(
                      'Size: $size, Quantity: $quantity',
                      style: TextStyle(color: Colors.teal[700]),
                    ),
                  );
                });

                // Animated card with premium design and border
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.95, end: 1.0),
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale as double,
                      child: child,
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.3),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.teal.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: Container(
                          height: 120.0,
                          width: 90.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal[200]!, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          'Name: $productname',
                          style: TextStyle(
                            color: Colors.teal[900],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black12,
                                blurRadius: 3,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sizeWidgets,
                          ),
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
}
