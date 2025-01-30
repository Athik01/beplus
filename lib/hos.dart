import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
class HOS extends StatelessWidget {
  final String customerId;

  HOS({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🛍️ My Recent Purchases',
          style: TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: RecentPurchases(userId: customerId),
    );
  }
}


class RecentPurchases extends StatelessWidget {
  final String userId;

  RecentPurchases({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('bills')
          .where('customerId', isEqualTo: userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.teal.shade700));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No recent purchases found!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          );
        }

        // Extract orders array from all matching bills
        List<dynamic> orders = [];
        for (var bill in snapshot.data!.docs) {
          if (bill['orders'] != null) {
            orders.addAll(bill['orders']);
          }
        }

        if (orders.isEmpty) {
          return Center(
            child: Text(
              'No orders found in your bills!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    var productId = order['productId'];
                    var selectedSize = order['selectedSize'] as Map<String, dynamic>? ?? {}; // Ensure it's a map
                    var orderDate = (order['orderDate'] as Timestamp).toDate();
                    var formattedDate = "${orderDate.day}-${orderDate.month}-${orderDate.year}";

                    // Convert selectedSize map to a readable string (e.g., "M: 2, L: 1")
                    String sizeDetails = selectedSize.entries
                        .map((entry) => "${entry.key}: ${entry.value}")
                        .join(", ");

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                      builder: (context, productSnapshot) {
                        if (productSnapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoadingCard();
                        }

                        if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                          return _buildErrorCard();
                        }

                        var productData = productSnapshot.data!;
                        String productName = productData['name'] ?? 'Unknown Product';
                        var imageBase64 = productData['imageUrl'] ?? '';

                        Uint8List? imageBytes;
                        if (imageBase64.isNotEmpty) {
                          try {
                            imageBytes = base64Decode(imageBase64);
                          } catch (_) {
                            imageBytes = null;
                          }
                        }

                        return _buildProductCard(productName, formattedDate, imageBytes, sizeDetails,order,context);
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
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal.shade700),
            SizedBox(height: 10),
            Text("Loading...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          "Error loading product",
          style: TextStyle(fontSize: 14, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildProductCard(String productName, String formattedDate, Uint8List? imageBytes, String sizeDetails, Map<String, dynamic> order,BuildContext context)  {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal.shade700, width: 1),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: imageBytes != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.memory(imageBytes, width: double.infinity, fit: BoxFit.cover),
                )
                    : Container(
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Sizes: $sizeDetails',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => _onReorder(context,order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text("Reorder", style: TextStyle(fontSize: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReorder(BuildContext context, Map<String, dynamic> order) async {
    try {
      // Update orderDate and status
      order['orderDate'] = Timestamp.now();
      order['status'] = "Not Confirmed";

      // Add updated order to Firestore in 'orders' collection
      await FirebaseFirestore.instance.collection('orders').add(order);

      // Show success message with Lottie animation
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.teal.shade700,
                ),
                SizedBox(height: 10),
                Text(
                  "Reorder placed successfully!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("OK", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("Failed to reorder: $e");
    }
  }

}




