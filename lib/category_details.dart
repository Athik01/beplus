import 'dart:convert';
import 'dart:typed_data';
import 'package:beplus/view_products.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryDetailsPage extends StatelessWidget {
  final String categoryId;

  const CategoryDetailsPage({Key? key, required this.categoryId}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '       Category Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
        ),
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
      ),
      body: Container(
        color: Colors.teal.shade50, // Light teal background
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('categories').doc(categoryId).get(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.teal)));
            }
            if (categorySnapshot.hasError) {
              return Center(child: Text('Error: ${categorySnapshot.error}', style: TextStyle(color: Colors.red, fontSize: 16)));
            }
            if (!categorySnapshot.hasData || !categorySnapshot.data!.exists) {
              return Center(child: Text('Category not found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)));
            }

            var categoryData = categorySnapshot.data!;
            String categoryName = categoryData['name'] ?? 'Unnamed Category';
            String imageBase64 = categoryData['image'] ?? '';
            String description = categoryData['description'] ?? 'No description available';
            String userId = categoryData['userId'] ?? '';

            // Decode Base64 image string
            Uint8List? imageBytes;
            if (imageBase64.isNotEmpty) {
              try {
                imageBytes = base64Decode(imageBase64);
              } catch (e) {
                print("Error decoding Base64 image: $e");
              }
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('categories').doc(categoryId).get(),
              builder: (context, categorySnapshot) {
                if (categorySnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.teal)));
                }
                if (categorySnapshot.hasError) {
                  return Center(child: Text('Error: ${categorySnapshot.error}', style: TextStyle(color: Colors.red, fontSize: 16)));
                }
                if (!categorySnapshot.hasData || !categorySnapshot.data!.exists) {
                  return Center(child: Text('Category not found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)));
                }

                var categoryData = categorySnapshot.data!;
                String categoryName = categoryData['name'] ?? 'Unnamed Category';
                String imageBase64 = categoryData['image'] ?? '';
                String description = categoryData['description'] ?? 'No description available';
                String userId = categoryData['userId'] ?? '';

// Image handling
                ImageProvider? imageProvider;

                if (imageBase64.startsWith('https://')) {
                  // Handle network image if the image is an HTTPS URL
                  imageProvider = NetworkImage(imageBase64);
                } else if (imageBase64.isNotEmpty) {
                  // Decode Base64 image string if it's not a URL
                  try {
                    // Attempt to decode the Base64 string
                    Uint8List imageBytes = base64Decode(imageBase64);
                    // Only set the imageProvider if decoding is successful
                    imageProvider = MemoryImage(imageBytes);
                  } catch (e) {
                    print("Error decoding Base64 image: $e");
                    // Fallback to a default image if base64 decoding fails
                    imageProvider = AssetImage('assets/default_image.png');  // Replace with your default image asset
                  }
                }


                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.teal)));
                    }
                    if (userSnapshot.hasError) {
                      return Center(child: Text('Error: ${userSnapshot.error}', style: TextStyle(color: Colors.red, fontSize: 16)));
                    }
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return Center(child: Text('User not found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)));
                    }

                    var userData = userSnapshot.data!;
                    Map<String, dynamic> userMap = userData.data() as Map<String, dynamic>;

                    String userName = userMap['name'] ?? 'Unknown User';
                    String userState = userMap['state'] ?? 'Unknown';
                    String? userImageBase64 = userMap.containsKey('image') ? userMap['image'] : null;
                    bool showFollowButton = true;
                    Uint8List? userImageBytes;
                    if (userImageBase64 != null && userImageBase64.isNotEmpty) {
                      try {
                        userImageBytes = base64Decode(userImageBase64);
                      } catch (e) {
                        print("Error decoding Base64 user image: $e");
                      }
                    }

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('requests')
                          .where('customerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .where('ownerId', isEqualTo: userId)
                          .get(),
                      builder: (context, requestSnapshot) {
                        if (requestSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.teal)));
                        }
                        if (requestSnapshot.hasError) {
                          return Center(child: Text('Error: ${requestSnapshot.error}', style: TextStyle(color: Colors.red, fontSize: 16)));
                        }

                        String followButtonText = 'Follow';
                        bool isRequested = false;

                        // Check if a request exists and its status
                        if (requestSnapshot.hasData && requestSnapshot.data!.docs.isNotEmpty) {
                          var requestDoc = requestSnapshot.data!.docs[0];
                          String status = requestDoc['status'] ?? '';
                          if (status == 'Not Confirmed') {
                            followButtonText = 'Requested';
                            isRequested = true;
                          }
                          else if (status == 'Confirmed') {
                            showFollowButton = false; // Hide the button for "Confirmed" status
                          }
                        }

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display decoded image or fallback UI
                              imageBytes != null
                                  ? Container(
                                width: double.infinity,
                                height: 380,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                                  child: imageBase64.startsWith('https://')
                                  // If imageBase64 is a URL, use NetworkImage
                                      ? Image.network(
                                    imageBase64,
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                  )
                                      : imageBase64.isNotEmpty
                                  // If imageBase64 is a Base64 string, decode and use MemoryImage
                                      ? Image.memory(
                                    base64Decode(imageBase64),
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    color: Colors.grey, // Fallback if no image available
                                    child: Center(
                                      child: Text(
                                        'No Image Available',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                                  : Container(
                                color: Colors.white,
                                width: double.infinity,
                                height: 250,
                                child: Center(
                                  child: Image.network(
                                    'https://img.freepik.com/premium-vector/product-concept-line-icon-simple-element-illustration-product-concept-outline-symbol-design-can-be-used-web-mobile-ui-ux_159242-2076.jpg',// Replace with your desired default image URL
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Category name with shadow and teal gradient effect
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    categoryName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade900,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(3.0, 3.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Category description with teal theme styling
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Text(
                                  description,
                                  style: TextStyle(fontSize: 20, color: Colors.teal.shade700, height: 1.5,fontStyle: FontStyle.italic),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Additional dynamic information with teal styling and modern card layout
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Card(
                                  color: Colors.teal.shade100,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.teal,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            userImageBytes != null
                                                ? CircleAvatar(
                                              radius: 50,
                                              backgroundImage: MemoryImage(userImageBytes),
                                            )
                                                : CircleAvatar(
                                              radius: 50,
                                              backgroundColor: Colors.grey.shade300,
                                              child: Icon(Icons.person, size: 50, color: Colors.grey.shade700),
                                            ),
                                            SizedBox(width: 16),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName,
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.teal,
                                                  ),
                                                ),
                                                Text(
                                                  'State: $userState',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.teal.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        // Conditional button display based on showFollowButton
                                        if (showFollowButton)
                                          ElevatedButton(
                                            onPressed: isRequested
                                                ? null
                                                : () async {
                                              try {
                                                // Get the current logged-in user's ID
                                                String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

                                                if (currentUserId != null) {
                                                  // Add a document to the 'requests' collection with the necessary data
                                                  await FirebaseFirestore.instance.collection('requests').add({
                                                    'customerId': currentUserId,
                                                    'ownerId': userId,
                                                    'status': 'Not Confirmed',
                                                    'timestamp': FieldValue.serverTimestamp(),
                                                  });

                                                  // Show feedback to the user
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Follow request sent!'),
                                                      backgroundColor: Colors.teal.shade700,
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Please log in to send a follow request.'),
                                                      backgroundColor: Colors.red.shade700,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error sending request: $e'),
                                                    backgroundColor: Colors.red.shade700,
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white, backgroundColor: Colors.teal, // Text color
                                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 25), // Padding for the button
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10), // Rounded corners
                                              ),
                                              elevation: 5, // Shadow effect
                                              shadowColor: Colors.black.withOpacity(0.3), // Shadow color
                                            ),
                                            child: Text(followButtonText),
                                          ),
                                        if (!showFollowButton)
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => ViewProductsPage(userId:userId,categoryName:categoryName)),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.white, backgroundColor: Colors.teal.shade700, // Set text color
                                              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0), // Padding around the button
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10), // Rounded corners
                                              ),
                                              shadowColor: Colors.teal.shade900, // Shadow color
                                              elevation: 5, // Button shadow
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min, // Makes the button size fit its content
                                              children: [
                                                Icon(
                                                  Icons.shopping_cart, // Add a shopping cart icon
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8), // Space between the icon and text
                                                Text(
                                                  'View Products',
                                                  style: TextStyle(
                                                    fontSize: 16, // Font size
                                                    fontWeight: FontWeight.bold, // Font weight for prominence
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (isRequested)
                                          Text(
                                            'Your request is under review.',
                                            style: TextStyle(
                                              color: Colors.teal.shade700,
                                              fontSize: 16,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}
