import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // Required for showing alert dialog
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class BillsGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isNoUpdate = true;
  String mobile = "";
  String email = "";
  String address = "";
  String shopName = "";
  String custName = "";
  String custShop = "";
  String custAddr = "";
  String custMobile = "";
  double discount = 0;
  Future<Map<String, dynamic>> fetchUserData(String ownerId) async {
    // Fetch the user data based on the ownerId
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return {}; // return an empty map if user not found
    }
  }
  double gstPercentage = 0;
  double cgstPercentage = 0.0;
  double sgstPercentage = 0.0;
  double discountPrice = 0.0;
  // Main function to generate and store the bill
  Future<void> GenerateBill(BuildContext context, List<String> orderIds) async {
    try {
      // Show dialog to get GST percentage from the user
      double gstPercentage = await _showGstDialog(context);
      List<Map<String, dynamic>> consolidatedOrders = [];
      double totalAmount = 0;
      var customerID = "";
      if (isNoUpdate) {
        for (var orderId in orderIds) {
          var orderData = await _fetchOrderData(orderId);
          customerID = orderData?['userId'];
          if (orderData != null) {
            consolidatedOrders.add(orderData);
            totalAmount += orderData['totalAmount'];
            // Update the order status to "done"
            await _updateOrderStatus(orderId);
          } else {
            print("Order ID not found: $orderId");
          }
        }

        if (consolidatedOrders.isNotEmpty) {
          Map<String, dynamic> billData = {
            "billDate": FieldValue.serverTimestamp(),
            "ownerId": FirebaseAuth.instance.currentUser!.uid,
            "customerId": customerID,
            "orders": consolidatedOrders,
            "totalAmount": totalAmount,
            "day": DateFormat('EEEE').format(DateTime.now()),
          };
          String ownerId = billData['ownerId'];
          await fetchUserData(ownerId).then((userData) {
            mobile = userData['mobile'] ?? 'Not Available';
            email = userData['email'] ?? 'Not Available';
            address = userData['address'] ?? 'Not Available';
            shopName = userData['shopName'] ?? 'Shop';
          });
          await fetchUserData(customerID).then((userData) {
            custMobile = userData['mobile'] ?? 'Not Available';
            custName = userData['name'] ?? 'Not Available';
            custAddr = userData['address'] ?? 'Not Available';
            custShop = userData['shopName'] ?? 'Shop';
          });
          final pdfBytes = await _generatePdf(
              consolidatedOrders, totalAmount, gstPercentage);
          final base64Pdf = base64Encode(Uint8List.fromList(pdfBytes));
          billData['pdfBase64'] = base64Pdf;
          await _firestore.collection('bills').add(billData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Bill generated and stored successfully!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              backgroundColor: Colors.teal,
              // A vibrant teal background
              duration: Duration(seconds: 3),
              // Customize the duration as needed
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    12), // Rounded corners for the SnackBar
              ),
              behavior: SnackBarBehavior.floating,
              // Makes it float above other content
              margin: EdgeInsets.all(16),
              // Add margin around the SnackBar
              elevation: 6, // Shadow effect
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No Bills Generated!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              backgroundColor: Colors.red.shade700,
              // Red background for error message
              duration: Duration(seconds: 4),
              // Customize the duration as needed
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
              behavior: SnackBarBehavior.floating,
              // Makes it float above other content
              margin: EdgeInsets.all(16),
              // Add margin around the SnackBar
              elevation: 6, // Shadow effect
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error generating bill: $e",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.red.shade700,
          // Red background for error message
          duration: Duration(seconds: 4),
          // Customize the duration as needed
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          behavior: SnackBarBehavior.floating,
          // Makes it float above other content
          margin: EdgeInsets.all(16),
          // Add margin around the SnackBar
          elevation: 6, // Shadow effect
        ),
      );
    }
  }

  // Function to show dialog to get GST percentage from the user
  Future<double> _showGstDialog(BuildContext context) async {
    TextEditingController cgstController = TextEditingController();
    TextEditingController sgstController = TextEditingController();
    TextEditingController discountController = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Column(
            children: [
              Text(
                "GST & Discount",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.teal,
                  height: 1.5,// Teal color for title text
                ),
              ),
              Divider(
                color: Colors.teal,
                thickness: 1.5,
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CGST Input Field
                TextField(
                  controller: cgstController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "CGST Percentage",
                    labelStyle: TextStyle(color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    hintText: "Enter CGST value",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 10),
                // SGST Input Field
                TextField(
                  controller: sgstController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "SGST Percentage",
                    labelStyle: TextStyle(color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    hintText: "Enter SGST value",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                SizedBox(height: 10),
                // Discount Percentage Input Field
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Discount Percentage",
                    labelStyle: TextStyle(color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    hintText: "Enter Discount Percentage",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Parse the values from the text controllers
                double cgst = double.tryParse(cgstController.text) ?? 0;
                double sgst = double.tryParse(sgstController.text) ?? 0;
                gstPercentage = cgst + sgst; // Calculate GST Percentage

                // Parse discount percentage and calculate discount price
                discount = double.tryParse(discountController.text) ?? 0;

                // Calculate the total GST
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.teal,  // Teal background for the button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                "OK",
                style: TextStyle(
                  color: Colors.white,  // White text on the button
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                isNoUpdate = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "No Bill generating bill!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    backgroundColor: Colors.red.shade700, // Red background for error message
                    duration: Duration(seconds: 4), // Customize the duration as needed
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    behavior: SnackBarBehavior.floating, // Makes it float above other content
                    margin: EdgeInsets.all(16), // Add margin around the SnackBar
                    elevation: 6, // Shadow effect
                  ),
                );
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,  // White background for cancel button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.teal),  // Teal border for cancel button
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.teal,  // Teal color for cancel text
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
    return gstPercentage;
  }


  Future<Map<String, dynamic>?> _fetchOrderData(String orderId) async {
    try {
      var orderSnapshot = await _firestore.collection('orders').doc(orderId).get();
      if (orderSnapshot.exists) {
        // Exclude sensitive fields like `userId` if needed
        Map<String, dynamic> orderData = orderSnapshot.data()!;
        return orderData;
      }
      return null;
    } catch (e) {
      print("Error fetching order data: $e");
      return null;
    }
  }

  // Function to update the status of an order to "done"
  Future<void> _updateOrderStatus(String orderId) async {
    if(isNoUpdate)
      try {
        await _firestore.collection('orders').doc(orderId).update({'status': 'done'});
        print("Order ID $orderId status updated to 'done'.");
      } catch (e) {
        print("Error updating order status for Order ID $orderId: $e");
      }
  }

  Future<Uint8List> _generatePdf(
      List<Map<String, dynamic>> orders,
      double totalAmount,
      double gstPercentage,
      ) async {
    final pdf = pw.Document();

    // Load the custom font from assets
    final fontData = await rootBundle.load('lib/assets/fonts/Roboto-Black.ttf');
    final ttf = pw.Font.ttf(fontData);

    List<Map<String, dynamic>> productsData = [];
    for (var order in orders) {
      String productId = order['productId'];

      print('Fetching product for ID: $productId');

      var productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (productDoc.exists) {
        print('Product found: ${productDoc.data()}');

        var priceMap = productDoc['price'] ?? {};
        print('Price map: $priceMap');

        var selectedSize = order['selectedSize'];
        var selectedSizeKey = selectedSize.keys.first;
        print('Selected size key for this order: $selectedSizeKey');

        var sizeData = priceMap[selectedSizeKey] ?? {};
        print('Size data: $sizeData');

        double sizePrice = sizeData['price'] ?? 0;
        int sizeQuantity = sizeData['quantity'] ?? 0;

        print('Price for size $selectedSizeKey: $sizePrice');
        print('Quantity for size $selectedSizeKey: $sizeQuantity');

        productsData.add({
          'productId': productId,
          'name': productDoc['name'] ?? 'Product Name',
          'size': priceMap,
        });

        print('Product added: ${productsData}');
      } else {
        print('Product not found for ID: $productId');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          double discountAmount = totalAmount * (discount / 100);
          discountPrice = totalAmount - discountAmount;
          double taxAmount = totalAmount * (gstPercentage / 100);
          double grandTotal = totalAmount + taxAmount;

          return pw.Padding(
            padding: pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,  // Centered the shop name
                      children: [
                        pw.Text(
                          '$shopName',  // Centered shop name
                          style: pw.TextStyle(
                            fontSize: 40,  // Slightly larger font for better prominence
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(Colors.teal.value),
                            font: ttf,
                          ),
                        ),
                        pw.Text(
                          'Date: ${DateTime.now().toString().split(' ')[0]}',  // Date formatted to 'YYYY-MM-DD'
                          style: pw.TextStyle(
                            fontSize: 12,
                            font: ttf,
                            color: PdfColor.fromInt(Colors.teal.value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

// Add space between the header and Billed To section
                pw.SizedBox(height: 20),

// Add the left-aligned contact information (Phone, Email, Address) above "Billed To"
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Phone: $mobile',
                          style: pw.TextStyle(
                            fontSize: 14,  // Increased font size for clarity
                            font: ttf,
                            color: PdfColor.fromInt(Colors.teal.value),
                          ),
                        ),
                        pw.SizedBox(height: 5),  // Added spacing between fields
                        pw.Text(
                          'Email: $email',
                          style: pw.TextStyle(
                            fontSize: 14,
                            font: ttf,
                            color: PdfColor.fromInt(Colors.teal.value),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Address: $address',
                          style: pw.TextStyle(
                            fontSize: 14,
                            font: ttf,
                            color: PdfColor.fromInt(Colors.teal.value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

// Billed To section (after the contact information)
                pw.SizedBox(height: 10),

                // Billed To
                pw.Text(
                  'Billed To:',
                  style: pw.TextStyle(
                    fontSize: 20, // Increased font size for better emphasis
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                    color: PdfColor.fromHex('#008080'), // Teal color
                  ),
                ),
                pw.SizedBox(height: 8), // Increased spacing after the header

                pw.Text(
                  'Name: $custName',
                  style: pw.TextStyle(
                    fontSize: 16, // Slightly larger font size for better readability
                    font: ttf,
                    color: PdfColor.fromHex('#2e8b57'), // Darker teal for a better contrast
                  ),
                ),
                pw.SizedBox(height: 4), // Small space between fields

                pw.Text(
                  'Shop Name: $custShop',
                  style: pw.TextStyle(
                    fontSize: 16,
                    font: ttf,
                    color: PdfColor.fromHex('#2e8b57'),
                  ),
                ),
                pw.SizedBox(height: 4),

// Address in a container with padding and wrapping
                pw.Container(
                  width: 500,
                  padding: pw.EdgeInsets.all(5), // Added padding for the address container
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#008080'), width: 1), // Border in teal color
                    borderRadius: pw.BorderRadius.circular(4), // Rounded corners for the address box
                  ),
                  child: pw.Text(
                    'Address: $custAddr',
                    style: pw.TextStyle(
                      fontSize: 14,
                      font: ttf,
                      color: PdfColor.fromHex('#2e8b57'),
                    ),
                    softWrap: true,
                    overflow: pw.TextOverflow.visible,
                  ),
                ),
                pw.SizedBox(height: 4),

                pw.Text(
                  'Mobile Number: $custMobile',
                  style: pw.TextStyle(
                    fontSize: 16,
                    font: ttf,
                    color: PdfColor.fromHex('#2e8b57'),
                  ),
                ),
                pw.SizedBox(height: 10), // Final spacing for visual balance

                // Table Rows
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5), // Adds lines between rows and columns
                  columnWidths: {
                    0: pw.FlexColumnWidth(3), // Column for product name
                    1: pw.FlexColumnWidth(1), // Column for size
                    2: pw.FlexColumnWidth(1), // Column for quantity
                    3: pw.FlexColumnWidth(1), // Column for price
                    4: pw.FlexColumnWidth(1), // Column for amount
                  },
                  children: [
                    // Table header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#008080')), // Teal background
                      children: [
                        pw.Text(
                          'Product Name',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#ffffff'), // White text color
                          ),
                        ),
                        pw.Text(
                          'Size',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#ffffff'), // White text color
                          ),
                        ),
                        pw.Text(
                          'Quantity',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#ffffff'), // White text color
                          ),
                        ),
                        pw.Text(
                          'Price',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#ffffff'), // White text color
                          ),
                        ),
                        pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#ffffff'), // White text color
                          ),
                        ),
                      ],
                    ),
                    // Table rows
                    ...orders.map((order) {
                      var matchedProduct = productsData.firstWhere(
                            (product) => product['productId'] == order['productId'],
                        orElse: () => {'productId': '', 'name': '', 'size': {}, 'price': 0.0},
                      );

                      List<pw.TableRow> sizeRows = [];

                      order['selectedSize']?.forEach((key, value) {
                        String sizeKey = key.toString();

                        if (matchedProduct['size']?.containsKey(sizeKey) ?? false) {
                          var sizeData = matchedProduct['size'][sizeKey];
                          double displayPrice = sizeData['price'] ?? 0.0;
                          int quantity = value;
                          double amount = displayPrice * quantity;

                          sizeRows.add(
                            pw.TableRow(
                              children: [
                                pw.Text(matchedProduct['name'] ?? (order['description'] ?? ''), style: pw.TextStyle(fontSize: 12, font: ttf)),
                                pw.Text(sizeKey, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: ttf)),
                                pw.Text(quantity.toString(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: ttf)),
                                pw.Text(displayPrice.toString(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: ttf)),
                                pw.Text('₹${amount.toStringAsFixed(2)}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: ttf)),
                              ],
                            ),
                          );
                        }
                      });

                      return sizeRows; // Add rows for each order
                    }).expand((rows) => rows), // Flatten list of lists into a single list
                  ],
                ),
                pw.SizedBox(height: 10),

                // Subtotal, Tax, and Grand Total
                pw.Divider(), // Divider for separation
                pw.SizedBox(height: 10), // Add some spacing for better readability

// Subtotal Section
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#008080')), // Border color for the table
                  children: [
                    // Subtotal Row
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Subtotal:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#008080'), // Teal color for label
                          ),
                        ),
                        pw.Text(
                          '₹$totalAmount',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#2e8b57'), // Slightly darker color for amount
                          ),
                          textAlign: pw.TextAlign.right, // Aligning amount to the right
                        ),
                      ],
                    ),
                    // GST Row
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'CGST: $cgstPercentage%, SGST: $sgstPercentage%',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#008080'), // Teal color for the text
                          ),
                        ),
                        pw.Text(
                          '₹$taxAmount',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#2e8b57'), // Slightly darker color for amount
                          ),
                          textAlign: pw.TextAlign.right, // Aligning amount to the right
                        ),
                      ],
                    ),
                    // Discount Row
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Discount: $discount%',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#008080'), // Teal color for label
                          ),
                        ),
                        pw.Text(
                          '₹$discountPrice',  // Displaying discount price
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#ff6347'), // Red color for discount
                          ),
                          textAlign: pw.TextAlign.right, // Aligning amount to the right
                        ),
                      ],
                    ),
                    // Grand Total Row
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Grand Total:',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#008080'), // Teal color for label
                          ),
                        ),
                        pw.Text(
                          '₹${grandTotal}',  // Subtracting discount from grand total
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#2e8b57'), // Slightly darker color for amount
                          ),
                          textAlign: pw.TextAlign.right, // Aligning amount to the right
                        ),
                      ],
                    ),
                    // Final Price After Discount Row
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'Final Price After Discount:',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#008080'), // Teal color for label
                          ),
                        ),
                        pw.Text(
                          '₹${grandTotal - discountPrice}',  // Displaying final price after discount
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                            color: PdfColor.fromHex('#2e8b57'), // Slightly darker color for amount
                          ),
                          textAlign: pw.TextAlign.right, // Aligning amount to the right
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10), // Add spacing at the end for visual balance
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontSize: 16,
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(Colors.teal.value),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
