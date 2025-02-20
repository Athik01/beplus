import 'dart:convert';
import 'dart:typed_data';
import 'package:beplus/OrderInfo.dart';
import 'package:beplus/product_details.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beplus/profile.dart';
import 'package:beplus/login.dart';
import 'package:beplus/manage_products.dart';
import 'package:animate_do/animate_do.dart';
import 'package:beplus/ViewBills.dart';
import 'package:beplus/product_visibility.dart';
import 'package:beplus/manage_parties.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:ui';
import 'ManageStatements.dart';
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
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        toolbarHeight: 5,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.96),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, -3),
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
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled, size: 30),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group, size: 30),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox.shrink(), // Empty space for floating button
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long, size: 30),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.price_change_outlined, size: 30),
                  label: '',
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  MdiIcons.plusCircle,
                  size: 40,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder Widgets for Pages

class HomeScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50, // Soft background
      body: Stack(
        children: [
          // Gradient Background
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.teal.shade100, Colors.teal.shade700],
                  radius: 1.3,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.teal.shade100, Colors.teal.shade700],
                  radius: 1.3,
                ),
              ),
            ),
          ),

          // Main Content
          Column(
            children: [
              SizedBox(height: 20),

              // Dashboard Title with Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.teal.shade300,
                        indent: 10,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Animated Feature Cards
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    FadeInUp(
                      duration: Duration(milliseconds: 300),
                      child: buildGlassCard(
                        icon: Icons.inventory_2,
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
                    ),
                    FadeInUp(
                      duration: Duration(milliseconds: 400),
                      child: buildGlassCard(
                        icon: Icons.groups,
                        title: 'Manage Parties',
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageParties(userId: userId),
                            ),
                          );
                        },
                      ),
                    ),
                    FadeInUp(
                      duration: Duration(milliseconds: 500),
                      child: buildGlassCard(
                        icon: Icons.receipt_long,
                        title: 'Statements',
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageStatements(userId: userId),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget buildGlassCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Frosted effect
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  // **Glowing Icon**
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withOpacity(0.7),
                          color.withOpacity(0.3),
                        ],
                        radius: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5), // Neon Glow Effect
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 28, color: Colors.white),
                  ),
                  SizedBox(width: 15),

                  // **Text with a Subtle Glow**
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // **Glowing Forward Arrow**
                  Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.9), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IconLoadingIndicator extends StatelessWidget {
  final double size;
  final IconData icon;
  final double iconSize;
  final Color color;
  final String loadingText;
  final TextStyle? textStyle;

  const IconLoadingIndicator({
    Key? key,
    this.size = 50.0,
    required this.icon,
    this.iconSize = 24.0,
    this.color = Colors.teal,
    this.loadingText = 'Loading...',
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Icon(
                icon,
                size: iconSize,
                color: color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          loadingText,
          style: textStyle ?? TextStyle(color: color),
        ),
      ],
    );
  }
}

class PartiesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllData(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: IconLoadingIndicator(icon: Icons.account_circle));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'An error occurred: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No Business Contacts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var user = snapshot.data![index];
            String customerID = user['customerId'];
            String photoURL = user['photoURL'] ?? '';
            String name = user['name'] ?? 'Unknown';
            String contactNumber = user['mobile'] ?? 'N/A';

            return _buildCustomerCard(
              context,
              customerID,
              photoURL,
              name,
              contactNumber,
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllData(String userId) async {
    try {
      // Fetch requests
      QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      if (requestSnapshot.docs.isEmpty) {
        return [];
      }

      // Fetch user data for each request
      List<Future<Map<String, dynamic>?>> userFutures = requestSnapshot.docs.map((doc) async {
        String customerId = doc['customerId'];
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(customerId)
            .get();

        if (userDoc.exists) {
          return {
            'customerId': customerId,
            'photoURL': userDoc['photoURL'] ?? '',
            'name': userDoc['name'] ?? 'Unknown',
            'mobile': userDoc['mobile'] ?? 'N/A',
          };
        } else {
          return null;
        }
      }).toList();

      // Wait for all user data to be fetched
      List<Map<String, dynamic>?> users = await Future.wait(userFutures);

      // Filter out any null results
      return users.where((user) => user != null).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  Widget _buildCustomerCard(
      BuildContext context,
      String customerID,
      String photoURL,
      String name,
      String contactNumber,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductVisibility(customerID: customerID),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade200, Colors.teal.shade800],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                offset: Offset(3, 3),
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: photoURL.isNotEmpty
                      ? NetworkImage(photoURL)
                      : AssetImage('assets/default_avatar.png') as ImageProvider,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            contactNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, ordersSnapshot) {
          if (ordersSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          if (!ordersSnapshot.hasData || ordersSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var orders = ordersSnapshot.data!.docs;

          return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _fetchMatchingOrders(orders, currentUserId, context),
            builder: (context, matchingOrdersSnapshot) {
              if (matchingOrdersSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
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

  Widget _buildLoadingScreen() {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated loading icon with a circular progress bar
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.teal),
              strokeWidth: 4.0, // Make the progress bar thicker for a better look
            ),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Please wait while we fetch your data.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7), // Light grey color for subtler text
              ),
            ),
          ],
        ),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, ordersSnapshot) {
          if (ordersSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen(); // Show loading indicator
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
                return _buildLoadingScreen(); // Show loading indicator
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

  Widget _buildLoadingScreen() {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated loading icon with a circular progress bar
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.teal),
              strokeWidth: 4.0, // Make the progress bar thicker for a better look
            ),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Please wait while we fetch your data.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7), // Light grey color for subtler text
              ),
            ),
          ],
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

  void _showOrderIdsScreen(BuildContext context, String userId, List<Map<String, dynamic>> orders) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(userId: userId, orders: orders),
      ),
    );
  }
}


