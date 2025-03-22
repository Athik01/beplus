import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class to store aggregated sales data per product.
class SalesAnalysis {
  final String productId;
  final String productName;
  final int availableQuantity; // Total available quantity from the product document.
  final int likeCount; // Number of users who liked the product.
  int orderCount; // Units sold (billed).
  double totalRevenue; // Total revenue from sold units.

  SalesAnalysis({
    required this.productId,
    required this.productName,
    required this.availableQuantity,
    required this.likeCount,
    this.orderCount = 0,
    this.totalRevenue = 0.0,
  });

  /// Calculated unsold quantity based on available inventory and sold units.
  int get unsoldQuantity => availableQuantity - orderCount;

  /// Conversion rate (%) = (billed units / available inventory) * 100.
  double get conversionRate =>
      availableQuantity > 0 ? (orderCount / availableQuantity) * 100 : 0;

  /// Average sale value per order.
  double get averageSaleValue => orderCount > 0 ? totalRevenue / orderCount : 0;

  /// Potential additional revenue if all unsold units were sold at the average sale price.
  double get potentialAdditionalRevenue => unsoldQuantity * averageSaleValue;
}

class CategoryDetailPage extends StatelessWidget {
  final String categoryName;
  final String userId; // The currently logged-in user's ID

  const CategoryDetailPage({
    Key? key,
    required this.categoryName,
    required this.userId,
  }) : super(key: key);

  Future<List<SalesAnalysis>> fetchSalesAnalysis() async {
    try {
      // Query bills where ownerId matches the provided userId.
      QuerySnapshot billsSnapshot = await FirebaseFirestore.instance
          .collection('bills')
          .where('ownerId', isEqualTo: userId)
          .get();

      // Gather all orders from these bills.
      List<Map<String, dynamic>> ordersList = [];
      for (var billDoc in billsSnapshot.docs) {
        final billData = billDoc.data() as Map<String, dynamic>;
        if (billData.containsKey('orders') && billData['orders'] is List) {
          List<dynamic> orders = billData['orders'];
          for (var order in orders) {
            if (order is Map<String, dynamic>) {
              ordersList.add(order);
            }
          }
        }
      }

      // Map to accumulate aggregated sales data keyed by productId.
      Map<String, SalesAnalysis> analysisMap = {};

      // Process each order.
      for (var order in ordersList) {
        String productId = order['productId'] ?? '';
        if (productId.isEmpty) continue;

        // Fetch product document from the products collection.
        DocumentSnapshot productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        if (!productDoc.exists) continue;
        final productData = productDoc.data() as Map<String, dynamic>;

        // Check if the product's category matches the selected category.
        String productCategory = productData['category'] ?? '';
        if (productCategory != categoryName) continue;

        // Safely extract order total amount.
        double orderAmount = 0.0;
        if (order['totalAmount'] is num) {
          orderAmount = (order['totalAmount'] as num).toDouble();
        }

        // Extract the available quantity from product's "price" map.
        int availableQuantity = 0;
        if (productData.containsKey('price') && productData['price'] is Map) {
          Map priceMap = productData['price'];
          // Sum up the quantity for all entries in the price map.
          for (var key in priceMap.keys) {
            var priceEntry = priceMap[key];
            if (priceEntry is Map &&
                priceEntry.containsKey('quantity') &&
                priceEntry['quantity'] is num) {
              availableQuantity += (priceEntry['quantity'] as num).toInt();
            }
          }
        }

        // Extract like count from the "likes" map.
        int likeCount = 0;
        if (productData.containsKey('likes') && productData['likes'] is Map) {
          likeCount = (productData['likes'] as Map).length;
        }

        // Aggregate data per product.
        if (analysisMap.containsKey(productId)) {
          analysisMap[productId]!.orderCount += 1;
          analysisMap[productId]!.totalRevenue += orderAmount;
        } else {
          String productName = productData['name'] ?? 'Unnamed Product';
          analysisMap[productId] = SalesAnalysis(
            productId: productId,
            productName: productName,
            availableQuantity: availableQuantity,
            likeCount: likeCount,
            orderCount: 1,
            totalRevenue: orderAmount,
          );
        }
      }
      return analysisMap.values.toList();
    } catch (e) {
      print('Error fetching sales analysis: $e');
      return [];
    }
  }

  /// Builds a summary dashboard from all product analysis data.
  Widget buildDashboard(List<SalesAnalysis> analysis) {
    // Compute overall totals.
    int totalOrders = analysis.fold(0, (sum, item) => sum + item.orderCount);
    double totalRevenue =
    analysis.fold(0.0, (sum, item) => sum + item.totalRevenue);
    int totalAvailable =
    analysis.fold(0, (sum, item) => sum + item.availableQuantity);
    double overallConversion =
    totalAvailable > 0 ? (totalOrders / totalAvailable) * 100 : 0;

    return Card(
      margin: EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              'Overall Business Summary',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[700]),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDashboardMetric(
                    icon: Icons.shopping_cart,
                    label: 'Orders',
                    value: '$totalOrders'),
                _buildDashboardMetric(
                    icon: Icons.currency_rupee,
                    label: 'Revenue',
                    value: '\₹${totalRevenue.toStringAsFixed(2)}'),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDashboardMetric(
                    icon: Icons.inventory,
                    label: 'Available',
                    value: '$totalAvailable'),
                _buildDashboardMetric(
                    icon: Icons.trending_up,
                    label: 'Conv. Rate',
                    value: '${overallConversion.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to display an individual metric.
  Widget _buildDashboardMetric(
      {required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal[700], size: 28),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
        title: Text(
          categoryName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
        body: FutureBuilder<List<SalesAnalysis>>(
        future: fetchSalesAnalysis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('No sales data available for $categoryName'));
          }
          List<SalesAnalysis> analysis = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Dashboard summary.
                buildDashboard(analysis),
                // List of individual product cards.
                ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: analysis.length,
                  itemBuilder: (context, index) {
                    final item = analysis[index];
                    return Card(
                      margin:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[800]),
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricTile(
                                    icon: Icons.shopping_cart,
                                    label: 'Sold',
                                    value: '${item.orderCount}'),
                                _buildMetricTile(
                                    icon: Icons.inventory,
                                    label: 'Available',
                                    value: '${item.availableQuantity}'),
                                _buildMetricTile(
                                    icon: Icons.currency_rupee,
                                    label: 'Revenue',
                                    value:
                                    '\₹${item.totalRevenue.toStringAsFixed(2)}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricTile(
                                    icon: Icons.trending_up,
                                    label: 'Conv. Rate',
                                    value:
                                    '${item.conversionRate.toStringAsFixed(1)}%'),
                                _buildMetricTile(
                                    icon: Icons.currency_rupee_sharp,
                                    label: 'Avg Sale',
                                    value:
                                    '\₹${item.averageSaleValue.toStringAsFixed(2)}'),
                                _buildMetricTile(
                                    icon: Icons.assessment,
                                    label: 'Potential Rev.',
                                    value:
                                    '\₹${item.potentialAdditionalRevenue.toStringAsFixed(2)}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.thumb_up,
                                    color: Colors.teal[700], size: 20),
                                SizedBox(width: 4),
                                Text('${item.likeCount} Likes'),
                              ],
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
        },
      ),
    );
  }

  /// Helper widget to display individual metric tiles in product cards.
  Widget _buildMetricTile(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal[700], size: 20),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal[800])),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        )
      ],
    );
  }
}
