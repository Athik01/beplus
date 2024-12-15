import 'dart:convert';
import 'dart:typed_data';
import 'package:beplus/OrderInfo.dart';
import 'package:beplus/product_details.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:beplus/profile.dart';
import 'package:beplus/login.dart';
import 'package:beplus/manage_products.dart';
import 'dart:math';
import 'package:beplus/ViewBills.dart';
import 'package:beplus/product_visibility.dart';
import 'package:beplus/manage_parties.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
class HomePage2 extends StatefulWidget {
  final User? user;
  HomePage2({Key? key, this.user}) : super(key: key);

  @override
  _HomePage2State createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  String? _username; // To store the fetched username
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }
  // Fetch the username from Firestore based on the current user
  Future<void> _fetchUsername() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users') // Assuming the users collection is named 'users'
            .doc(currentUser.uid)
            .get();

        if (userSnapshot.exists && userSnapshot['name'] != null) {
          setState(() {
            _username = userSnapshot['name']; // Set the username
          });
        }
      }
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _username != null ? 'Welcome, $_username' : 'Loading...',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade400],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'JK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Since 1970',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.teal),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginApp()),
                  );
                } catch (e) {
                  print("Error during logout: $e");
                }
              },
            ),
          ],
        ),
      ),
      body: MainScreen(),
      );
  }


  // Frosted Glass Card Widget
}
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    PartiesScreen(),
    ProductsScreen(),
    BillsScreen(),
    BalanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        toolbarHeight: 4,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.teal,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          showSelectedLabels: true,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group, size: 30),
              label: 'Parties',
            ),
            BottomNavigationBarItem(
              icon: Icon(MdiIcons.plusCircleOutline, size: 30), // Example of a more stylish plus icon
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt, size: 30),
              label: 'Bills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.price_change_outlined, size: 30),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder Widgets for Pages
class HomeScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background animation
        AnimatedBackground(),
        // Main content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Manage Products Card
              _buildGlassCard(
                icon: Icons.inventory,
                title: 'Manage Products',
                color: Colors.tealAccent,
                onTap: () {
                  if (userId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageProducts(userId: userId),
                      ),
                    );
                  } else {
                    print('User not logged in');
                  }
                },
              ),
              // Manage Parties Card
              _buildGlassCard(
                icon: Icons.people_alt_outlined,
                title: 'Manage Parties',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageParties(userId: userId),
                    ),
                  );
                },
              ),
              // Bills Card
              _buildGlassCard(
                icon: Icons.receipt_long,
                title: 'Bills',
                color: Colors.orangeAccent,
                onTap: () {
                  print('Navigating to Bills');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.2), // Frosted glass effect
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 140,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
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


class PartiesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Fetch the currently logged-in user's ID
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder(
      future: _fetchRequests(currentUserId),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No Business Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          );
        }

        // Display Cards for each request that matches the criteria
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var request = snapshot.data![index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(request['customerId'])
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return Center(child: Text('Customer not found.'));
                }

                var user = userSnapshot.data!;
                String customerID = userSnapshot.data!.id;
                String photoURL = user['photoURL'] ?? '';
                String name = user['name'] ?? 'Unknown';
                String contactNumber = user['mobile'] ?? 'N/A';

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Color(0xffF5F5F5)], // Gradient from dark to light
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to ProductVisibility with the customerID
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductVisibility(customerID: customerID),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Display customer's image with a border and shadow for emphasis
                            photoURL.isNotEmpty
                                ? CircleAvatar(
                              radius: 45,
                              backgroundImage: NetworkImage(photoURL),
                              backgroundColor: Colors.white,
                            )
                                : CircleAvatar(
                              radius: 45,
                              child: Icon(Icons.person, size: 50, color: Colors.black),
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(width: 10), // Spacing for readability
                            // Display customer details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // White for better contrast
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contact: $contactNumber',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white, // White text color
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 24,
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

  Future<List<Map<String, dynamic>>> _fetchRequests(String userId) async {
    // Fetch requests collection where the ownerId matches and status is "Confirmed"
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('ownerId', isEqualTo: userId)
        .where('status', isEqualTo: 'Confirmed')
        .get();

    List<Map<String, dynamic>> requests = snapshot.docs.map((doc) {
      return {
        'customerId': doc['customerId'],
        'status': doc['status'],
        'ownerId': doc['ownerId'],
      };
    }).toList();

    return requests;
  }
}



class ProductsScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    // Trigger navigation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId.isNotEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AddItemDialog(userId: userId),
        );
      } else {
        // Handle the case where the user ID is empty (e.g., show an error or redirect to login)
        print('User not logged in');
      }
    });

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .where('userId', isEqualTo: userId) // Match userId in products collection
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a loading indicator while waiting for data
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Handle empty state if no products are found
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No products available.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else {
          // Display products in a ListView
          var products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index].data() as Map<String, dynamic>;
              Uint8List? imageBytes;
              String productId = products[index].id;
              // Check if imageUrl is present and decode it
              if (product['imageUrl'] != null && product['imageUrl'] is String) {
                try {
                  imageBytes = base64Decode(product['imageUrl']);
                } catch (e) {
                  // Handle any base64 decoding error gracefully
                  imageBytes = null;
                }
              }

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetails(productId:productId),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        child: imageBytes != null
                            ? Image.memory(
                          imageBytes,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          color: Colors.grey[300],
                          height: 180,
                          width: double.infinity,
                          child: Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[600],
                              size: 60,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                product['name'] ?? 'No Name',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Text(
                          'Tap for details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}


class BillsScreen extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.price_change,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'Bills',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade300,
        elevation: 4.0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, ordersSnapshot) {
          if (ordersSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }

          if (!ordersSnapshot.hasData || ordersSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var orders = ordersSnapshot.data!.docs;

          return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _fetchMatchingOrders(orders, currentUserId, context),
            builder: (context, matchingOrdersSnapshot) {
              if (matchingOrdersSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }

              if (!matchingOrdersSnapshot.hasData || matchingOrdersSnapshot.data!.isEmpty) {
                return _buildEmptyState(message: 'No matching orders found for the current user.');
              }

              return _buildOrderList(matchingOrdersSnapshot.data!);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation(Colors.blue),
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No bills generated!'}) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildOrderList(Map<String, List<Map<String, dynamic>>> userOrdersMap) {
    return ListView.builder(
      padding: EdgeInsets.all(12.0),
      itemCount: userOrdersMap.keys.length,
      itemBuilder: (context, index) {
        String userId = userOrdersMap.keys.elementAt(index);
        List<Map<String, dynamic>> userOrders = userOrdersMap[userId]!;
        String name = userOrders[0]['name'];
        String photoURL = userOrders[0]['photoURL'] ?? 'https://www.w3schools.com/howto/img_avatar.png';
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(photoURL),
              radius: 30,
            ),
            title: Text(
              'Name: $name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'View bills!',
              style: TextStyle(fontSize: 14, color: Colors.blue),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue),
            onTap: () {
              _showOrderIdsScreen(context, userId, userOrders);
            },
          ),
        );
      },
    );
  }

  void _showOrderIdsScreen(BuildContext context, String userId, List<Map<String, dynamic>> orders) {
    String ownerId = FirebaseAuth.instance.currentUser!.uid; // The current user as the customer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewBills(
          customerId: userId,
          ownerId: ownerId, // Passing the userId as ownerId
        ),
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMatchingOrders(
      List<QueryDocumentSnapshot> orders, String currentUserId, BuildContext context) async {
    Map<String, List<Map<String, dynamic>>> userOrdersMap = {};

    for (var order in orders) {
      String productId = order['productId'];
      DocumentSnapshot productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();

      if (productDoc.exists) {
        String productUserId = productDoc['userId'];
        if (productUserId == currentUserId) {
          // Group orders by userId and fetch user information
          String orderUserId = order['userId'];

          // Fetch user data from the 'users' collection
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(orderUserId).get();
          if (userDoc.exists) {
            String name = userDoc['name'] ?? 'Unknown';
            String photoURL = userDoc['photoURL'];

            if (!userOrdersMap.containsKey(orderUserId)) {
              userOrdersMap[orderUserId] = [];
            }
            userOrdersMap[orderUserId]!.add({
              'orderId': order.id,
              'name': name,
              'photoURL': photoURL,
              'orderDate': order['orderDate'],
              'selectedSize': order['selectedSize'],
              'status': order['status'],
              'totalAmount': order['totalAmount'],
              'productId': order['productId'],
            });
          }
        }
      }
    }

    return userOrdersMap;
  }
}




class BalanceScreen extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'View Orders',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade300,
        elevation: 4.0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, ordersSnapshot) {
          if (ordersSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            );
          }

          if (!ordersSnapshot.hasData || ordersSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No orders found.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            );
          }

          var orders = ordersSnapshot.data!.docs;
          return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _fetchMatchingOrders(orders, currentUserId, context),
            builder: (context, matchingOrdersSnapshot) {
              if (matchingOrdersSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                  ),
                );
              }
              if (!matchingOrdersSnapshot.hasData || matchingOrdersSnapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No matching orders found for the current user.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                itemCount: matchingOrdersSnapshot.data!.keys.length,
                itemBuilder: (context, index) {
                  String userId = matchingOrdersSnapshot.data!.keys.elementAt(index);
                  List<Map<String, dynamic>> userOrders = matchingOrdersSnapshot.data![userId]!;

                  // Retrieve user information (name and photoURL)
                  String name = userOrders[0]['name'];
                  String photoURL = userOrders[0]['photoURL'] ?? 'https://www.w3schools.com/howto/img_avatar.png';
                  List<Map<String, dynamic>> activeOrders = userOrders
                      .where((order) => order['status'] != 'done')
                      .toList();
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(photoURL),
                        radius: 30,
                      ),
                      title: Text(
                        'Name: $name',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Total Orders: ${activeOrders.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue),
                      onTap: () {
                        _showOrderIdsScreen(context, name, userOrders);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMatchingOrders(
      List<QueryDocumentSnapshot> orders, String currentUserId, BuildContext context) async {
    Map<String, List<Map<String, dynamic>>> userOrdersMap = {};

    for (var order in orders) {
      String productId = order['productId'];
      DocumentSnapshot productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();

      if (productDoc.exists) {
        String productUserId = productDoc['userId'];
        if (productUserId == currentUserId) {
          // Group orders by userId and fetch user information
          String orderUserId = order['userId'];

          // Fetch user data from the 'users' collection
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(orderUserId).get();
          if (userDoc.exists) {
            String name = userDoc['name'] ?? 'Unknown';
            String photoURL = userDoc['photoURL'];

            if (!userOrdersMap.containsKey(orderUserId)) {
              userOrdersMap[orderUserId] = [];
            }
            userOrdersMap[orderUserId]!.add({
              'orderId': order.id,
              'name': name,
              'photoURL': photoURL,
              'orderDate': order['orderDate'],
              'selectedSize': order['selectedSize'],
              'status': order['status'],
              'totalAmount': order['totalAmount'],
              'productId': order['productId'],
            });
          }
        }
      }
    }

    return userOrdersMap;
  }

  void _showOrderIdsScreen(BuildContext context, String userId, List<Map<String, dynamic>> orders) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(userId: userId, orders: orders),
      ),
    );
  }
}


class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated Background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorTween(
                      begin: Colors.teal.shade700,
                      end: Colors.purple.shade800,
                    ).evaluate(_controller)!,
                    ColorTween(
                      begin: Colors.deepPurple.shade400,
                      end: Colors.blue.shade900,
                    ).evaluate(_controller)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        ),
        // Bubbles Layer
        BubbleWidget(size: 60, animationDuration: Duration(seconds: 17)),
        BubbleWidget(size: 90, animationDuration: Duration(seconds: 7)),
        BubbleWidget(size: 120, animationDuration: Duration(seconds: 14)),
        BubbleWidget(size: 80, animationDuration: Duration(seconds: 10)),
      ],
    );
  }
}

class BubbleWidget extends StatefulWidget {
  final double size;
  final Duration animationDuration;

  const BubbleWidget({
    required this.size,
    required this.animationDuration,
  });

  @override
  _BubbleWidgetState createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget> with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with infinite looping
    _bubbleController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat(reverse: true); // Make the animation repeat

    // Circular path animation (sine and cosine for circular movement)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159265359) // Full circle (2π)
        .animate(CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation, // Make sure _rotationAnimation is being used here
      builder: (context, child) {
        // Calculate the new position using sine and cosine for a circular path
        double radius = 200; // Radius of the circular path
        double centerX = MediaQuery.of(context).size.width / 2; // Center X of the screen
        double centerY = MediaQuery.of(context).size.height / 2; // Center Y of the screen

        // Circular motion: sine and cosine functions
        double x = centerX + radius * cos(_rotationAnimation.value); // X position
        double y = centerY + radius * sin(_rotationAnimation.value); // Y position

        return Positioned(
          left: x - widget.size / 2, // Adjust to center the bubble
          top: y - widget.size / 2, // Adjust to center the bubble
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        );
      },
    );
  }
}

