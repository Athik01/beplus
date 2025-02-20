import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // Required for showing alert dialog
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:number_to_words/number_to_words.dart';
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
          var statementsRef = _firestore.collection('statements');
          var querySnapshot = await statementsRef
              .where('ownerId', isEqualTo: ownerId)
              .where('customerId', isEqualTo: customerID)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // Update existing document
            var doc = querySnapshot.docs.first;
            double existingCredit = doc['credit'] ?? 0;
            double existingDebit = doc['debit'] ?? 0;
            double newCredit = existingCredit + totalAmount;
            double newBalance = newCredit - existingDebit;

            await statementsRef.doc(doc.id).update({
              'credit': newCredit,
              'balance': newBalance,
            });
          } else {
            // Create a new document
            await statementsRef.add({
              'ownerId': ownerId,
              'customerId': customerID,
              'credit': totalAmount,
              'debit': 0,
              'balance': totalAmount,
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle, // Checkmark symbol
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 8), // Add some space between the icon and text
                  Text(
                    "Bill generated successfully!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600, // Vibrant green background
              duration: Duration(seconds: 3), // Customize the duration as needed
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners for the SnackBar
              ),
              behavior: SnackBarBehavior.floating, // Makes it float above other content
              margin: EdgeInsets.all(16), // Add margin around the SnackBar
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
                cgstPercentage = double.tryParse(cgstController.text) ?? 0;
                sgstPercentage = double.tryParse(sgstController.text) ?? 0;
                gstPercentage = cgstPercentage + sgstPercentage; // Calculate GST Percentage

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
      // Fetch the order document from the orders collection
      var orderSnapshot = await _firestore.collection('orders').doc(orderId).get();

      if (orderSnapshot.exists) {
        Map<String, dynamic> orderData = orderSnapshot.data()!;

        // Extract productId and selectedSize from the orders collection
        String productId = orderData['productId'];
        Map<String, dynamic> selectedSize = orderData['selectedSize'];

        // Fetch the matching product document from the products collection
        var productSnapshot = await _firestore.collection('products').doc(productId).get();

        if (productSnapshot.exists) {
          Map<String, dynamic> productData = productSnapshot.data()!;

          // Fetch the price map from the product document
          Map<String, dynamic> priceMap = productData['price'];

          // Update the quantity in the price map based on the selectedSize
          selectedSize.forEach((size, selectedQuantity) {
            if (priceMap.containsKey(size)) {
              Map<String, dynamic> sizeDetails = priceMap[size];
              int currentQuantity = sizeDetails['quantity'];
              num newQuantity = currentQuantity - selectedQuantity;

              // Ensure quantity does not go below zero
              sizeDetails['quantity'] = newQuantity >= 0 ? newQuantity : 0;

              // Update the price map in the product document
              priceMap[size] = sizeDetails;
            }
          });

          // Update the product document in Firestore
          await _firestore.collection('products').doc(productId).update({
            'price': priceMap,
          });
        }

        // Return the order data excluding sensitive fields if needed
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
        pageFormat: PdfPageFormat.a3,
        build: (pw.Context context) {
          double taxAmount = totalAmount * (gstPercentage / 100);
          double grandTotal = totalAmount + taxAmount;
          double discountAmount = grandTotal * (discount / 100);
          discountPrice = discountAmount;
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
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Shop name with stylish design
                        pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 5), // Add spacing below shop name
                          child: pw.Text(
                            '$shopName',
                            style: pw.TextStyle(
                              fontSize: 42, // Larger font for emphasis
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#008080'), // Teal color
                              font: ttf,
                            ),
                          ),
                        ),
                        // Decorative line below shop name
                        pw.Container(
                          width: 150,
                          height: 2,
                          color: PdfColor.fromHex('#20B2AA'), // Lighter teal for subtle decoration
                          margin: const pw.EdgeInsets.only(bottom: 10), // Spacing below the line
                        ),
                        // Date with additional styling
                        pw.Text(
                          'Date: ${DateTime.now().toString().split(' ')[0]}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.normal,
                            color: PdfColor.fromHex('#004D40'), // Dark teal for contrast
                            font: ttf,
                          ),
                        ),
                        // Additional tagline or subtitle
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 5), // Add spacing above the tagline
                          child: pw.Text(
                            'Your Trusted Partner in Quality Products',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColor.fromHex('#20B2AA'), // Light teal for subtlety
                              font: ttf,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: pw.EdgeInsets.all(10), // Add padding around the content
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#008080'), width: 1), // Teal border
                    borderRadius: pw.BorderRadius.circular(6), // Rounded corners for a sleek look
                    color: PdfColor.fromHex('#F0F8F8'), // Light teal background
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    crossAxisAlignment: pw.CrossAxisAlignment.start, // Align items to the top
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Phone Information
                          pw.Row(
                            children: [
                              pw.Text(
                                'Phone: ',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  font: ttf,
                                  color: PdfColor.fromHex('#008080'), // Teal for key
                                ),
                              ),
                              pw.Text(
                                '$mobile',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  font: ttf,
                                  color: PdfColor.fromHex('#2e8b57'), // Dark teal for value
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),

                          // Email Information
                          pw.Row(
                            children: [
                              pw.Text(
                                'Email: ',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  font: ttf,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Text(
                                '$email',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  font: ttf,
                                  color: PdfColor.fromHex('#2e8b57'),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),

                          // Address Information with Wrapping
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Address: ',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  font: ttf,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  '$address',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    font: ttf,
                                    color: PdfColor.fromHex('#2e8b57'),
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


// Billed To section (after the contact information)
                pw.SizedBox(height: 10),
                // Billed To
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header: "Billed To"
                    pw.Text(
                      'Billed To:',
                      style: pw.TextStyle(
                        fontSize: 22, // Increased size for prominence
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                        color: PdfColor.fromHex('#008080'), // Teal for consistency
                      ),
                    ),
                    pw.SizedBox(height: 10), // Extra spacing for separation

                    // Customer Details in Key-Value format
                    pw.Container(
                      padding: pw.EdgeInsets.all(10), // Add padding for a neat layout
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColor.fromHex('#008080'), width: 1), // Teal border
                        borderRadius: pw.BorderRadius.circular(6), // Rounded corners
                        color: PdfColor.fromHex('#F0F8F8'), // Light teal background for contrast
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Customer Name
                          pw.Row(
                            children: [
                              pw.Text(
                                'Name: ',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  font: ttf,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Text(
                                '$custName',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: ttf,
                                  color: PdfColor.fromHex('#2e8b57'),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),

                          // Customer Shop Name
                          pw.Row(
                            children: [
                              pw.Text(
                                'Shop Name: ',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  font: ttf,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Text(
                                '$custShop',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: ttf,
                                  color: PdfColor.fromHex('#2e8b57'),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),

                          // Customer Address with wrapping
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Address: ',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  font: ttf,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  '$custAddr',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    font: ttf,
                                    color: PdfColor.fromHex('#2e8b57'),
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),

                          // Customer Mobile Number
                          pw.Row(
                            children: [
                              pw.Text(
                                'Mobile Number: ',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  font: ttf,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Text(
                                '$custMobile',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: ttf,
                                  color: PdfColor.fromHex('#2e8b57'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10), // Additional spacing after the details box
                  ],
                ),

                // Table Rows
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5), // Adds borders for the grid
                  columnWidths: {
                    0: pw.FlexColumnWidth(3), // Column for product name
                    1: pw.FlexColumnWidth(1), // Column for size
                    2: pw.FlexColumnWidth(1), // Column for quantity
                    3: pw.FlexColumnWidth(1), // Column for price
                    4: pw.FlexColumnWidth(1), // Column for amount
                  },
                  children: [
                    // Table header with dark teal background
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#004d4d')), // Dark teal
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Product Name',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#ffffff'), // White text color
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Size',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#ffffff'), // White text color
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Quantity',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#ffffff'), // White text color
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Price',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#ffffff'), // White text color
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Amount',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#ffffff'), // White text color
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Table rows with alternating light teal, white, and green colors
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
                          if (quantity == 0) return;
                          double amount = displayPrice * quantity;
                          sizeRows.add(
                            pw.TableRow(
                              decoration: pw.BoxDecoration(
                                color: sizeRows.length % 3 == 0
                                    ? PdfColor.fromHex('#e0f7f7') // Light teal for first row
                                    : sizeRows.length % 3 == 1
                                    ? PdfColor.fromHex('#f9fff9') // White for second row
                                    : PdfColor.fromHex('#d8f3dc'), // Light green for third row
                              ),
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(matchedProduct['name'] ?? (order['description'] ?? ''), style: pw.TextStyle(fontSize: 12, font: ttf)),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(sizeKey, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: ttf)),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(quantity.toString(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: ttf)),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(displayPrice.toString(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: ttf)),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text('₹${amount.toStringAsFixed(2)}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, font: ttf)),
                                ),
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
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#008080'), width: 1.0), // Border for grid
                  children: [
                    // Subtotal Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#f0f8ff'), // Light blue for alternate row
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Subtotal:',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#008080'),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹$totalAmount',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#2e8b57'),
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // GST Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#ffffff'), // White for alternate row
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'CGST: $cgstPercentage%, SGST: $sgstPercentage%',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#008080'),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹$taxAmount',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#2e8b57'),
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Grand Total Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#d3f9d8'), // Light green for total row
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Grand Total:',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#008080'),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹${grandTotal}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#2e8b57'),
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Discount Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#f0f8ff'), // Light blue for alternate row
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Discount: $discount%',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#008080'),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹$discountPrice',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#ff6347'),
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Final Price After Discount Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#d3f9d8'), // Light green for total row
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Final Price After Discount:',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#008080'),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '₹${(grandTotal - discountPrice).toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#2e8b57'),
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#d3f9d8'), // Light green for total row
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Final Amount in Words',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#008080'),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            convertNumberToWords((grandTotal - discountPrice)),
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              font: ttf,
                              color: PdfColor.fromHex('#2e8b57'),
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                pw.SizedBox(height: 10), // Add spacing at the end for visual balance
                pw.Divider(),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  String convertNumberToWords(double d) {
    int integerPart = d.toInt();
    String words = NumberToWord().convert('en-in', integerPart);
    String titleCaseWords = words.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
    return "$titleCaseWords Only/-";
  }

}