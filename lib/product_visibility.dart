import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';

class ProductVisibility extends StatelessWidget {
  final String customerID;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  ProductVisibility({required this.customerID});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.visibility,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'Product Visibility',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal[800],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(customerID)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Customer not found'));
          }
          print(userId);
          var customerData = snapshot.data!.data() as Map<String, dynamic>;
          String name = customerData['name'] ?? 'N/A';
          String mobile = customerData['mobile'] ?? 'N/A';
          String shopName = customerData['shopName'] ?? 'N/A';
          String state = customerData['state'] ?? 'N/A';
          String address = customerData['address'] ?? 'N/A';
          String photoURL = customerData['photoURL'] ?? 'https://example.com/default-image.png';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Customer Image Card
                Card(
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.network(
                          photoURL,
                          height: 180,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer Details and Tabs
                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: Colors.teal[800],
                        tabs: [
                          Tab(
                            icon: Icon(Icons.person, color: Colors.teal[800], size: 28),
                            child: Text(
                              'Customer Details',
                              style: TextStyle(
                                color: Colors.teal[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Tab(
                            icon: Icon(Icons.visibility, color: Colors.teal[800], size: 28),
                            child: Text(
                              'Product Visibility',
                              style: TextStyle(
                                color: Colors.teal[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 400,
                        child: TabBarView(
                          children: [
                            // Customer Details Tab
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Customer Details',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal[800],
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.symmetric(vertical: 8),
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.teal[300]!, Colors.teal[800]!],
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.phone, color: Colors.teal[800]),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Mobile: $mobile',
                                              style: TextStyle(fontSize: 16, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.store, color: Colors.teal[800]),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Shop Name: $shopName',
                                              style: TextStyle(fontSize: 16, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.location_on, color: Colors.teal[800]),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'State: $state',
                                              style: TextStyle(fontSize: 16, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.home, color: Colors.teal[800]),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Address: $address',
                                              style: TextStyle(fontSize: 16, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.teal[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.all(8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_outline, color: Colors.teal[800]),
                                            SizedBox(width: 8),
                                            Text(
                                              'All information is verified',
                                              style: TextStyle(fontSize: 14, color: Colors.teal[800]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Replace the Product Visibility Tab content
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('products')
                                    .where('userId', isEqualTo: userId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(child: Text('Error: ${snapshot.error}'));
                                  }
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return Center(child: Text('No products found for this user.'));
                                  }

                                  var products = snapshot.data!.docs;

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      var product = products[index];
                                      String productId = product.id; // Fetch the document ID
                                      String productName = product['name'] ?? 'Unnamed Product';
                                      List<dynamic> productSizes = product['size'] ?? [];
                                      String imageURL = product['imageUrl'] ?? ''; // Base64 image string
                                      List<dynamic> visibility = product['visibility'] ?? []; // Existing visibility field

                                      // Convert Base64 to Image
                                      final imageBytes = Base64Decoder().convert(imageURL);

                                      // Convert size list to a string
                                      String sizeString = productSizes.join(', ');

                                      // Determine the icon based on the current visibility
                                      bool isVisible = visibility.contains(customerID);

                                      return Card(
                                        margin: EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        elevation: 5,
                                        child: ListTile(
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.memory(
                                              imageBytes,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: 50),
                                            ),
                                          ),
                                          title: Text(
                                            productName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal[800],
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Sizes: $sizeString',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              isVisible ? Icons.visibility : Icons.hide_source,
                                              color: Colors.teal[800],
                                            ),
                                            onPressed: () async {
                                              try {
                                                final productRef = FirebaseFirestore.instance.collection('products').doc(productId);

                                                // If 'visibility' field is null or doesn't exist, initialize it as an empty list
                                                if (visibility == null || visibility.isEmpty) {
                                                  await productRef.update({
                                                    'visibility': [],
                                                  });
                                                }

                                                if (isVisible) {
                                                  // Remove the customerId from the visibility array
                                                  await productRef.update({
                                                    'visibility': FieldValue.arrayRemove([customerID]),
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              'Product visibility removed for this customer.',
                                                              style: TextStyle(
                                                                fontSize: 16, // Larger font size for readability
                                                                fontWeight: FontWeight.bold, // Bold text for emphasis
                                                                color: Colors.white, // White text for better contrast
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(width: 10), // Add some space between the text and the icon
                                                        ],
                                                      ),
                                                      backgroundColor: Colors.redAccent, // Red background for a warning
                                                      behavior: SnackBarBehavior.floating, // Floating SnackBar for a modern look
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10), // Rounded corners for a smoother look
                                                      ),
                                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Comfortable padding
                                                      duration: Duration(seconds: 4), // Slightly longer duration for the warning
                                                    ),
                                                  );
                                                } else {
                                                  // Add the customerId to the visibility array
                                                  await productRef.update({
                                                    'visibility': FieldValue.arrayUnion([customerID]),
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Product visibility added for this customer.',
                                                        style: TextStyle(
                                                          fontSize: 16, // Larger text for better readability
                                                          fontWeight: FontWeight.bold, // Emphasize the text
                                                          color: Colors.white, // White text color for better contrast
                                                        ),
                                                      ),
                                                      backgroundColor: Colors.teal, // Set a background color to match the theme
                                                      behavior: SnackBarBehavior.floating, // Floating effect to make it more prominent
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10), // Rounded corners for a modern look
                                                      ),
                                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding for a comfortable size
                                                      duration: Duration(seconds: 3), // Adjust the duration of the SnackBar
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error updating visibility: $e')),
                                                );
                                              }
                                            },
                                          ),
                                          onTap: () {
                                            // Show an AlertDialog with the larger image
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white, // White background for the dialog
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20), // Rounded corners for a smooth look
                                                  ),
                                                  title: Column(
                                                    children: [
                                                      Text(
                                                        productName,
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.teal[800], // Match the theme color
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      SizedBox(height: 10), // Add spacing between title and image
                                                      Divider(color: Colors.teal[800], thickness: 1), // Add a divider for better separation
                                                    ],
                                                  ),
                                                  content: ClipRRect(
                                                    borderRadius: BorderRadius.circular(15), // Rounded corners for the image
                                                    child: Image.memory(
                                                      imageBytes, // Use the existing imageBytes
                                                      fit: BoxFit.contain, // Maintain the aspect ratio
                                                      width: MediaQuery.of(context).size.width * 0.8, // 80% of the screen width
                                                      height: MediaQuery.of(context).size.height * 0.6, // 60% of the screen height
                                                    ),
                                                  ),
                                                  actions: <Widget>[
                                                    Padding(
                                                      padding: const EdgeInsets.only(bottom: 10), // Padding at the bottom of the dialog
                                                      child: TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop(); // Close the dialog
                                                        },
                                                        child: Text(
                                                          'Close',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.teal[800], // Theme color for button text
                                                            fontSize: 16, // Slightly larger text for the button
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
