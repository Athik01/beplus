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
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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
      body: _pages[_currentIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.96),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
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
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper to create a curved bottom for the AppBar
class AppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HomeScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      // Custom curved AppBar with premium gradient background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipPath(
            clipper: AppBarClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueGrey.shade800,
                    Colors.blueGrey.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          title: Text(
            'WholeSellers! :)',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
      Container(
        decoration: BoxDecoration(
        gradient: LinearGradient(
        colors: [
        Colors.white,
        Colors.blueGrey.shade50,
        ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      ),
      image: DecorationImage(
        image: AssetImage('lib/assets/back.png'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Colors.white.withOpacity(0.1), // Light white faded effect
          BlendMode.dstATop,
        ),
      ),
    ),
    ),

    // Decorative elements for extra depth
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueGrey.shade100,
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueGrey.shade100,
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          // Main content area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting section with user's name and profile photo
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return premiumGreeting("Hey, Loading...", null,context);
                      }
                      if (snapshot.hasError) {
                        return premiumGreeting("Hey, User", null,context);
                      }
                      final userData = snapshot.data;
                      String name = userData?['name'] ?? 'User';
                      String photoURL = userData?['photoURL'] ?? '';
                      return premiumGreeting("Hey, $name", photoURL,context);
                    },
                  ),
                  const SizedBox(height: 30),
                  // Premium cards arranged in a grid-like layout with animations
    Expanded(
    child: AnimationLimiter(
    child: Column(
    children: [
    // First row with 2 cards
    Row(
    children: [
    // Card 1
    Expanded(
    child: AnimationConfiguration.staggeredList(
    position: 0,
    duration: const Duration(milliseconds: 600),
    child: SlideAnimation(
    verticalOffset: 50.0,
    child: FadeInAnimation(
    child: Container(
    decoration: BoxDecoration(
    image: DecorationImage(
    image: AssetImage('lib/assets/back2.png'),
    fit: BoxFit.cover,
    ),
    borderRadius: BorderRadius.circular(16), // Rounded corners for a clean look
    ),
    child: SizedBox(
    height: 250, // Increased height
    child: buildStyledCard(
    context,
    icon: Icons.inventory_2,
    iconBgColor: Colors.greenAccent,
    title: 'Manage Products',
    subtitle: 'Easily manage your entire product catalog.',
    onTap: () {
    if (userId.isNotEmpty) {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) =>
    ManageProducts(userId: userId),
    ),
    );
    } else {
    print("User not logged in");
    }
    },
    ),
    ),
    ),
    ),
    ),
    ),
    ),
    const SizedBox(width: 16),
    // Card 2
    Expanded(
    child: AnimationConfiguration.staggeredList(
    position: 1,
    duration: const Duration(milliseconds: 600),
    child: SlideAnimation(
    verticalOffset: 50.0,
    child: FadeInAnimation(
    child: Container(
    decoration: BoxDecoration(
    image: DecorationImage(
    image: AssetImage('lib/assets/back2.png'),
    fit: BoxFit.cover,
    ),
    borderRadius: BorderRadius.circular(16),
    ),
    child: SizedBox(
    height: 250,
    child: buildStyledCard(
    context,
    icon: Icons.groups,
    iconBgColor: Colors.orangeAccent,
    title: 'Manage Parties',
    subtitle: 'Keep track of your business partners.',
    onTap: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) =>
    ManageParties(userId: userId),
    ),
    );
    },
    ),
    ),
    ),
    ),
    ),
    ),
    ),
    ],
    ),

    const SizedBox(height: 16),
    // Second row with the 3rd card (spanning the width)
    AnimationConfiguration.staggeredList(
    position: 2,
    duration: const Duration(milliseconds: 600),
    child: SlideAnimation(
    verticalOffset: 50.0,
    child: FadeInAnimation(
    child: Container(
    decoration: BoxDecoration(
    image: DecorationImage(
    image: AssetImage('lib/assets/back2.png'),
    fit: BoxFit.cover,
    ),
    borderRadius: BorderRadius.circular(16),
    ),
    child: SizedBox(
    height: 200,
    width: double.infinity,
    child: buildStyledCard(
    context,
    icon: Icons.receipt_long,
    iconBgColor: Colors.blueAccent,
    title: 'Statements',
    subtitle: 'Generate and view financial statements instantly.',
    onTap: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => TallyERP(),
    ),
    );
    },
    ),
    ),
    ),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium greeting widget with custom typography and profile avatar
  Widget premiumGreeting(String greeting, String? photoURL, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          greeting,
          style: GoogleFonts.montserrat(
            textStyle: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade800,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
          child: photoURL != null && photoURL.isNotEmpty
              ? CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(photoURL),
          )
              : CircleAvatar(
            radius: 26,
            backgroundColor: Colors.blueGrey.shade200,
            child: Icon(Icons.person, color: Colors.blueGrey.shade700),
          ),
        ),
      ],
    );
  }
  /// Card styled to match the reference image:
  /// - Colored circle with icon at top-left
  /// - Title to the right of icon
  /// - Subtitle below the title
  Widget buildStyledCard(
      BuildContext context, {
        required IconData icon,
        required Color iconBgColor,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(20), // Increased padding for larger card size
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Slightly larger corners
          border: Border.all(color: Colors.blueGrey.shade50, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.shade100.withOpacity(0.7),
              blurRadius: 15,
              offset: const Offset(4, 4),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 15,
              offset: Offset(-4, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Align icon to the top right
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 21, // Increased icon size
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12), // Space between icon and text

            // Title and subtitle text
            Text(
              title,
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  fontSize: 16, // Increased font size for title
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                textStyle: TextStyle(
                  fontSize: 14, // Increased font size for subtitle
                  fontWeight: FontWeight.w400,
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ),
          ],
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
    this.color = Colors.black,
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

    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'My Parties!',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        elevation: 0,
      ),
      body: Column(
        children: [
          // SizedBox for spacing after the AppBar
          Expanded(
            child: Stack(
              children: [
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'lib/assets/back.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // White fading overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.8), // More opaque at top
                          Colors.white.withOpacity(0.3), // Less opaque at bottom
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content from FutureBuilder
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAllData(currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: IconLoadingIndicator(icon: Icons.account_circle),
                      );
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
                      padding: const EdgeInsets.only(
                        top: 16,
                        left: 12,
                        right: 12,
                        bottom: 8,
                      ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllData(String userId) async {
    try {
      QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('ownerId', isEqualTo: userId)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      if (requestSnapshot.docs.isEmpty) {
        return [];
      }

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

      List<Map<String, dynamic>?> users = await Future.wait(userFutures);
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
          // Outer container with the asset image as a border-like background
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: AssetImage('lib/assets/back2.png'),
              fit: BoxFit.cover,
            ),
          ),
          // Padding to create the border effect
          child: Padding(
            padding: const EdgeInsets.all(4.0), // Adjust thickness of the "border" here
            child: Container(
              // Inner container with white background for content
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: photoURL.isNotEmpty
                        ? NetworkImage(photoURL)
                        : const AssetImage('assets/default_avatar.png')
                    as ImageProvider,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.black, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              contactNumber,
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black,
                    size: 18,
                  ),
                ],
              ),
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

    return Container(
      // Background image for the entire page
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/back2.png'),
          fit: BoxFit.cover,
        ),
      ),
      // White fading effect overlay
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.9), // More white at the top
              Colors.white.withOpacity(0.6), // Fades to transparent at the bottom
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.blueGrey,
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.production_quantity_limits, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Products',
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('products')
                .where('userId', isEqualTo: userId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No products available.',
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
                        imageBytes = null;
                      }
                    }
                    // Wrap the Card with a Container that uses the asset as a border image.
                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('lib/assets/back2.png'),
                          fit: BoxFit.fill,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.all(8), // adjust for border width
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: Card(
                        margin: EdgeInsets.zero,
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
                                builder: (context) => ProductDetails(productId: productId),
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
                                        style: GoogleFonts.montserrat(
                                          textStyle: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontStyle: FontStyle.italic,
                                          ),
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
                                  style: GoogleFonts.montserrat(
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}


class BillsScreen extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Blue-grey AppBar with Montserrat font
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'My Bills!',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        iconTheme: IconThemeData(color: Colors.white),
      ),

        body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/back.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
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
                  return _buildEmptyState(
                    message: 'No matching orders found for the current user.',
                  );
                }

                return _buildOrderList(matchingOrdersSnapshot.data!);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Stack(
      children: [
        // This container represents the underlying screen content.
        // Remove or replace if the background is provided elsewhere.
        Container(
          width: double.infinity,
          height: double.infinity,
        ),
        // Full-screen blur overlay.
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withOpacity(0.0),
          ),
        ),
        // Centered loading container with glass effect.
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 250,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                    strokeWidth: 4.0,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please wait while we fetch your data.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({String message = 'No bills generated!'}) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.montserrat(
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
        String photoURL = userOrders[0]['photoURL'] ??
            'https://www.w3schools.com/howto/img_avatar.png';

        // Wrap each card in a container to apply an image border using lib/assets/back2.png
        return Container(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          padding: EdgeInsets.all(4.0), // adjust this value for border thickness
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/back2.png'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Card(
            margin: EdgeInsets.zero, // remove default margin inside the border container
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
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'View bills!',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue),
              onTap: () {
                _showOrderIdsScreen(context, userId, userOrders);
              },
            ),
          ),
        );
      },
    );
  }

  void _showOrderIdsScreen(BuildContext context, String userId, List<Map<String, dynamic>> orders) {
    String ownerId = FirebaseAuth.instance.currentUser!.uid;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewBills(
          customerId: userId,
          ownerId: ownerId,
        ),
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMatchingOrders(
      List<QueryDocumentSnapshot> orders,
      String currentUserId,
      BuildContext context,
      ) async {
    Map<String, List<Map<String, dynamic>>> userOrdersMap = {};

    for (var order in orders) {
      String productId = order['productId'];
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (productDoc.exists) {
        String productUserId = productDoc['userId'];
        if (productUserId == currentUserId) {
          String orderUserId = order['userId'];

          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(orderUserId)
              .get();
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
      // Blue-grey AppBar with Montserrat-styled title
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_rupee_sharp, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Balance',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color : Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueGrey,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      // The overall background uses lib/assets/back.png with a white fading effect.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/back.png'),
            fit: BoxFit.cover,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').snapshots(),
          builder: (context, ordersSnapshot) {
            if (ordersSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (!ordersSnapshot.hasData || ordersSnapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No orders found.',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            var orders = ordersSnapshot.data!.docs;
            return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: _fetchMatchingOrders(orders, currentUserId, context),
              builder: (context, matchingOrdersSnapshot) {
                if (matchingOrdersSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }
                if (!matchingOrdersSnapshot.hasData || matchingOrdersSnapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching orders found for the current user.',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
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
                    String photoURL = userOrders[0]['photoURL'] ??
                        'https://www.w3schools.com/howto/img_avatar.png';
                    List<Map<String, dynamic>> activeOrders = userOrders
                        .where((order) => order['status'] != 'done')
                        .toList();

                    // Wrap each card in a Container with a background image of lib/assets/back2.png
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      padding: EdgeInsets.all(4), // Adjust this for desired border thickness
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('lib/assets/back2.png'),
                          fit: BoxFit.fill,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(photoURL),
                            radius: 30,
                          ),
                          title: Text(
                            'Name: $name',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Total Orders: ${activeOrders.length}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue),
                          onTap: () {
                            _showOrderIdsScreen(context, name, userOrders);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Stack(
      children: [
        // Underlying content container (if needed)
        Container(
          width: double.infinity,
          height: double.infinity,
        ),
        // Full-screen blur overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withOpacity(0.0),
          ),
        ),
        // Centered loading container with glass effect
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 250,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                    strokeWidth: 4.0,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please wait while we fetch your data.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMatchingOrders(
      List<QueryDocumentSnapshot> orders,
      String currentUserId,
      BuildContext context,
      ) async {
    Map<String, List<Map<String, dynamic>>> userOrdersMap = {};

    for (var order in orders) {
      String productId = order['productId'];
      DocumentSnapshot productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (productDoc.exists) {
        String productUserId = productDoc['userId'];
        if (productUserId == currentUserId) {
          // Group orders by userId and fetch user information
          String orderUserId = order['userId'];

          // Fetch user data from the 'users' collection
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(orderUserId)
              .get();
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