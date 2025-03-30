import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductVisibility extends StatelessWidget {
  final String customerID;
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  ProductVisibility({required this.customerID});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/back.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.8), // More white at the top
              Colors.white.withOpacity(0.0), // Fades to transparent at the bottom
            ],
          ),
        ),
        // Wrap the Scaffold with a Theme widget to apply Google Fonts Montserrat across the page
        child: Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.montserratTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Row(
                children: [
                  Text(''),
                  Icon(
                    Icons.visibility,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Product Visibility',
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blueGrey,
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
                var customerData =
                snapshot.data!.data() as Map<String, dynamic>;
                String name = customerData['name'] ?? 'N/A';
                String mobile = customerData['mobile'] ?? 'N/A';
                String shopName = customerData['shopName'] ?? 'N/A';
                String state = customerData['state'] ?? 'N/A';
                String address = customerData['address'] ?? 'N/A';
                String photoURL = customerData['photoURL'] ??
                    'https://example.com/default-image.png';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Customer Image Card
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(3), // This padding creates the border effect
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: AssetImage('lib/assets/back2.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Slightly smaller radius to show border
                          ),
                          elevation: 5,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Display the main image from network
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.network(
                                  photoURL,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Centered text for the card
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Customer Details and Tabs
                      DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('lib/assets/back2.png'),
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.all(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TabBar(
                                  indicatorColor: Colors.black,
                                  tabs: [
                                    Tab(
                                      icon: Icon(Icons.person,
                                          color: Colors.black, size: 28),
                                      child: Text(
                                        'Customer Details',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Tab(
                                      icon: Icon(Icons.visibility,
                                          color: Colors.black, size: 28),
                                      child: Text(
                                        'Product Visibility',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              height: 400,
                              child: TabBarView(
                                children: [
                                  // Customer Details Tab
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage('lib/assets/back2.png'),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: EdgeInsets.all(4),
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        elevation: 5,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Customer Details',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal[800],
                                                  fontFamily: 'Montserrat',
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 8),
                                                height: 2,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.teal[300]!,
                                                      Colors.teal[800]!
                                                    ],
                                                  ),
                                                  borderRadius:
                                                  BorderRadius.circular(4),
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              buildDetailRow(
                                                  Icons.phone, 'Mobile: $mobile'),
                                              SizedBox(height: 12),
                                              buildDetailRow(Icons.store,
                                                  'Shop Name: $shopName'),
                                              SizedBox(height: 12),
                                              buildDetailRow(Icons.location_on,
                                                  'State: $state'),
                                              SizedBox(height: 12),
                                              buildDetailRow(Icons.home,
                                                  'Address: $address'),
                                              SizedBox(height: 16),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.teal[50],
                                                  borderRadius:
                                                  BorderRadius.circular(8),
                                                ),
                                                padding: EdgeInsets.all(8),
                                                child: Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        color: Colors.teal[800]),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'All information is verified',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.teal[800]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Product Visibility Tab
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('products')
                                          .where('userId', isEqualTo: userId)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                              child:
                                              CircularProgressIndicator());
                                        }
                                        if (snapshot.hasError) {
                                          return Center(
                                              child: Text(
                                                  'Error: ${snapshot.error}'));
                                        }
                                        if (!snapshot.hasData ||
                                            snapshot.data!.docs.isEmpty) {
                                          return Center(
                                              child: Text(
                                                  'No products found for this user.'));
                                        }

                                        var products = snapshot.data!.docs;

                                        return ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: products.length,
                                          itemBuilder: (context, index) {
                                            var product = products[index];
                                            String productId = product.id;
                                            String productName =
                                                product['name'] ??
                                                    'Unnamed Product';
                                            List<dynamic> productSizes =
                                                product['size'] ?? [];
                                            String imageURL =
                                                product['imageUrl'] ?? '';
                                            List<dynamic> visibility =
                                                product['visibility'] ?? [];

                                            // Convert Base64 to Image
                                            final imageBytes =
                                            Base64Decoder().convert(imageURL);

                                            // Convert size list to a string
                                            String sizeString =
                                            productSizes.join(', ');

                                            // Determine visibility icon
                                            bool isVisible =
                                            visibility.contains(customerID);

                                            return Container(
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      'lib/assets/back2.png'),
                                                  fit: BoxFit.cover,
                                                ),
                                                borderRadius:
                                                BorderRadius.circular(15),
                                              ),
                                              margin: EdgeInsets.symmetric(
                                                  vertical: 8),
                                              padding: EdgeInsets.all(2),
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(15),
                                                ),
                                                elevation: 5,
                                                child: ListTile(
                                                  leading: ClipRRect(
                                                    borderRadius:
                                                    BorderRadius.circular(8),
                                                    child: Image.memory(
                                                      imageBytes,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error,
                                                          stackTrace) =>
                                                          Icon(Icons.error,
                                                              size: 50),
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
                                                      isVisible
                                                          ? Icons.visibility
                                                          : Icons.hide_source,
                                                      color: Colors.teal[800],
                                                    ),
                                                    onPressed: () async {
                                                      try {
                                                        final productRef =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                            'products')
                                                            .doc(productId);
                                                        if (isVisible) {
                                                          await productRef.update({
                                                            'visibility':
                                                            FieldValue
                                                                .arrayRemove([
                                                              customerID
                                                            ]),
                                                          });
                                                        } else {
                                                          await productRef.update({
                                                            'visibility':
                                                            FieldValue
                                                                .arrayUnion([
                                                              customerID
                                                            ]),
                                                          });
                                                        }
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                            context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'Error updating visibility: $e')),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  onTap: () {
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (BuildContext context) {
                                                        return AlertDialog(
                                                          backgroundColor:
                                                          Colors.white,
                                                          shape:
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                                20),
                                                          ),
                                                          title: Column(
                                                            children: [
                                                              Text(
                                                                productName,
                                                                style: TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                                  color: Colors
                                                                      .teal[
                                                                  800],
                                                                ),
                                                                textAlign:
                                                                TextAlign
                                                                    .center,
                                                              ),
                                                              SizedBox(
                                                                  height: 10),
                                                              Divider(
                                                                  color: Colors
                                                                      .teal[
                                                                  800],
                                                                  thickness: 1),
                                                            ],
                                                          ),
                                                          content: ClipRRect(
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                            child: Image.memory(
                                                              imageBytes,
                                                              fit: BoxFit.contain,
                                                              width: MediaQuery.of(
                                                                  context)
                                                                  .size
                                                                  .width *
                                                                  0.8,
                                                              height: MediaQuery.of(
                                                                  context)
                                                                  .size
                                                                  .height *
                                                                  0.6,
                                                            ),
                                                          ),
                                                          actions: <Widget>[
                                                            Padding(
                                                              padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 10),
                                                              child: TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                      context)
                                                                      .pop();
                                                                },
                                                                child: Text(
                                                                  'Close',
                                                                  style:
                                                                  TextStyle(
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                    color: Colors
                                                                        .teal[800],
                                                                    fontSize: 16,
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
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal[800]),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500, // Adjust weight if desired
            ),
          ),
        ),
      ],
    );
  }
}
