import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'generateBills.dart';


class OrderDetailsScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> orders;

  OrderDetailsScreen({required this.userId, required this.orders});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  List<Map<String, dynamic>> filterOrders(String status) {
    return widget.orders.where((order) => order['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Orders for ${widget.userId}',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/back.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // White fading gradient overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
          ),
          // Main content: Column with TabBar and TabBarView
          Column(
            children: [
              // TabBar placed below the AppBar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(4), // Adjust for border thickness
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('lib/assets/back2.png'),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  color: Colors.blueGrey.shade300,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.blueGrey,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.normal),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.check_circle),
                        text: 'Confirmed',
                      ),
                      Tab(
                        icon: Icon(Icons.new_releases),
                        text: 'New Orders',
                      ),
                      Tab(
                        icon: Icon(Icons.cancel),
                        text: 'Cancelled',
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded TabBarView for content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    buildOrderList(filterOrders('Confirmed'), 'Confirmed'),
                    buildOrderList(filterOrders('Not Confirmed'), 'Not Confirmed'),
                    buildOrderList(filterOrders('Cancelled'), 'Cancelled'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget buildOrderList(List<Map<String, dynamic>> orders, String currentStatus) {
    bool showButtons = orders.any((order) => order['status'] == 'Confirmed');

    return Column(
      children: [
        Expanded(
          child: orders.isEmpty
              ? Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                'No orders available.',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
              : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .doc(order['productId'])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return ListTile(
                      title: Text(
                        'Failed to load product details',
                        style: GoogleFonts.montserrat(
                            color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                      leading: Icon(Icons.error, color: Colors.red),
                    );
                  }

                  final productData = snapshot.data!.data() as Map<String, dynamic>;
                  final productName = productData['name'] ?? 'Unknown Product';
                  final base64Image = productData['imageUrl'] ?? '';
                  ImageProvider imageProvider;
                  String selectedSizeDetails = '';
                  if (order['selectedSize'] != null &&
                      order['selectedSize'] is Map) {
                    order['selectedSize'].forEach((key, value) {
                      selectedSizeDetails += 'Size $key: $value\n';
                    });
                  } else {
                    selectedSizeDetails = 'No size details available';
                  }
                  if (base64Image.isNotEmpty) {
                    try {
                      final bytes = base64Decode(base64Image);
                      imageProvider = MemoryImage(bytes);
                    } catch (e) {
                      imageProvider = AssetImage('assets/default_product.png');
                    }
                  } else {
                    imageProvider = AssetImage('assets/default_product.png');
                  }

                  // Wrap the Card in a Container with a padding and decoration to simulate a border using the asset image
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                    padding: EdgeInsets.all(4), // Adjust for border thickness
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('lib/assets/back2.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image(
                                    image: imageProvider,
                                    height: 70,
                                    width: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Total Amount: ₹${order['totalAmount']}',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.blueGrey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 24, thickness: 1, color: Colors.grey[300]),
                            Text(
                              'Selected Size:',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              selectedSizeDetails,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Status: ${order['status']}',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    color: order['status'] == 'Cancelled'
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Order Date: ${DateFormat('MMMM d, yyyy').format(order['orderDate'].toDate())}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (order['status'] == 'Not Confirmed') ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => updateOrderStatus(order['orderId'], 'Confirmed'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        shadowColor: Colors.green.withOpacity(0.5),
                                        elevation: 4,
                                      ),
                                      icon: Icon(Icons.check, color: Colors.white),
                                      label: Text(
                                        'Approve',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => updateOrderStatus(order['orderId'], 'Cancelled'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        shadowColor: Colors.red.withOpacity(0.5),
                                        elevation: 4,
                                      ),
                                      icon: Icon(Icons.close, color: Colors.white),
                                      label: Text(
                                        'Cancel',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (showButtons)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // Fetch all orders with status 'Confirmed'
                    List<String> confirmedOrderIds = [];
                    QuerySnapshot snapshot = await FirebaseFirestore.instance
                        .collection('orders')
                        .where('status', isEqualTo: 'Confirmed')
                        .get();
                    for (var doc in snapshot.docs) {
                      confirmedOrderIds.add(doc.id);
                    }
                    if (confirmedOrderIds.isNotEmpty) {
                      print("Confirmed Order IDs: $confirmedOrderIds");
                      BillsGenerator generateBill = BillsGenerator();
                      await generateBill.GenerateBill(context, confirmedOrderIds);
                      Navigator.pop(context);
                    } else {
                      print("No confirmed orders found.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Generate Bills',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
      ],
    );
  }

  void updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
      setState(() {
        widget.orders.firstWhere((order) => order['orderId'] == orderId)['status'] = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
