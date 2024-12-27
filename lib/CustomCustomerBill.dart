import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
class CustomBill extends StatefulWidget {
  final String customerId;

  const CustomBill({Key? key, required this.customerId}) : super(key: key);

  @override
  _CustomBillState createState() => _CustomBillState();
}

class _CustomBillState extends State<CustomBill> {
  final List<Map<String, dynamic>> billItems = [];
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController taxController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  double totalAmount = 0.0;
  double taxRate = 0.0; // Default tax rate
  String custName = "";
  String custShop = "";
  String custAddr = "";
  String custMobile = "";
  void addItem() {
    String itemName = itemNameController.text.trim();
    int quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    double price = double.tryParse(priceController.text.trim()) ?? 0.0;
    int size = int.tryParse(sizeController.text.trim()) ?? 0;
    if (itemName.isNotEmpty && quantity > 0 && price > 0.0) {
      setState(() {
        double itemTotal = quantity * price;
        billItems.add({
          'itemName': itemName,
          'quantity': quantity,
          'price': price,
          'itemTotal': itemTotal,
          'size': size,
        });
        totalAmount += itemTotal;
        itemNameController.clear();
        quantityController.clear();
        priceController.clear();
        sizeController.clear();
      });
    } else {
      _showSnackbar('Please provide valid item details.');
    }
  }

  Future<void> processOrdersAndUpdateQuantity(
      BuildContext context,
      String currentUserId,
      String itemNameController,
      int sizeController,
      int quantityController,
      ) async {
    try {
      // Fetch orders for the current user that are marked as 'done'
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'done')
          .get();

      // Check if no orders are found
      if (ordersSnapshot.docs.isEmpty) {
        print("No orders found.");
        return;
      }

      // Process each order
      for (var order in ordersSnapshot.docs) {
        String productId = order['productId'];
        DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        // Check if product exists and fetch its name
        if (!productSnapshot.exists) {
          continue; // Skip this iteration and check next order
        }

        String productName = productSnapshot['name'];
        if (productName == itemNameController) {
          // Fetch the sizes and quantities for this product
          var selectedSize = Map<String, dynamic>.from(
              order['selectedSize']?.map((key, value) => MapEntry(key, value)) ?? {});

          String selectedSizeKey = sizeController.toString();
          if (selectedSize.containsKey(selectedSizeKey)) {
            int quantityToSubtract = quantityController;
            bool quantityUpdated = false;

            // Loop through available quantities for the selected size across multiple collections
            for (var sizeKey in selectedSize.keys) {
              if (sizeKey == selectedSizeKey) {
                int currentQuantity = selectedSize[sizeKey];

                // Subtract the available quantity and move to the next collection if necessary
                while (quantityToSubtract > 0 && currentQuantity > 0) {
                  // If the quantity to subtract is less than the available quantity, subtract it
                  if (currentQuantity >= quantityToSubtract) {
                    selectedSize[sizeKey] = currentQuantity - quantityToSubtract;
                    quantityToSubtract = 0; // Successfully subtracted, exit loop
                    quantityUpdated = true;
                    break;
                  } else {
                    // Subtract all of this collection's quantity and move to the next collection
                    selectedSize[sizeKey] = 0;
                    quantityToSubtract -= currentQuantity;
                    print('Moving to next collection. Remaining quantity to subtract: $quantityToSubtract');
                  }
                }
              }
              // If all required quantity has been subtracted, break the loop
              if (quantityToSubtract == 0) break;
            }

            // After looping through sizes and sub-collections, if any quantity was updated, save to Firestore
            if (quantityToSubtract == 0) {
              await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
                'selectedSize': selectedSize,
              });
              print('Quantity successfully updated for product: $productName');
              return;
            } else {
              print('Insufficient quantity across all collections for size $selectedSizeKey in $productName');
            }
          }
        }
      }

      print('No matching product found or quantity update unsuccessful.');
    } catch (e) {
      print('Error processing orders: $e');
    }
  }



  void updateTaxRate() {
    double enteredTax = double.tryParse(taxController.text.trim()) ?? 0.0;
    if (enteredTax >= 0.0) {
      setState(() {
        taxRate = enteredTax / 100; // Convert percentage to decimal
      });
    } else {
      _showSnackbar('Tax rate cannot be negative.');
    }
  }

  double calculateTax() => totalAmount * taxRate;

  double calculateGrandTotal() => totalAmount + calculateTax();

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void removeItem(int index) {
    setState(() {
      totalAmount -= billItems[index]['itemTotal'];
      billItems.removeAt(index);
    });
  }
  void generateBill() async {
    String customerName = '';
    // Show the dialog to collect the customer name
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Enter Customer Name',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  onChanged: (value) {
                    customerName = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Customer Name',
                    hintStyle: TextStyle(color: Colors.blueGrey.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blueGrey),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Check if the customer name is provided
                        if (customerName.isNotEmpty) {
                          showGeneratedBill(customerName);
                        } else {
                          // Show an error message or handle the case when customer name is empty
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a customer name.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.teal),
                        padding: MaterialStateProperty.all(
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      child: Text(
                        'Generate Bill',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void showGeneratedBill(String customerName) async {
    double totalAmount = 0.0;

    // Iterate through each bill item and calculate the total amount
    billItems.forEach((item) {
      totalAmount += item['itemTotal'];
    });

    // You can use the totalAmount in the UI, for example, to display it in the bill.
    print("Total Amount: $totalAmount");

    // Now, update the order quantity based on the item details from billItems
    for (var item in billItems) {
      String itemName = item['itemName'];  // Get item name
      int size = item['size'];          // Get item size
      int quantity = item['quantity'];  // Get item quantity

      // Print the item name for debugging
      print("Processing Item: $itemName");

      // Ensure processOrdersAndUpdateQuantity is awaited
      await processOrdersAndUpdateQuantity(
        context,
        widget.customerId,  // Ensure this customer ID is correct
        itemName,           // Use itemName from billItems
        size,               // Use item size from billItems
        quantity, // Convert quantity to string
      );
    }

    // Optionally, do something after all items are processed, like updating the UI
    print("All items processed.");
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
    await fetchUserData(widget.customerId).then((userData) {
      custMobile = userData['mobile'] ?? 'Not Available';
      custName = userData['name'] ?? 'Not Available';
      custAddr = userData['address'] ?? 'Not Available';
      custShop = userData['shopName'] ?? 'Shop';
    });

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('hh:mm:ss a').format(now);
    String formattedDay = DateFormat('EEEE').format(now);

    // Create PDF document
    final pdf = pw.Document();

// Use a font that supports ₹ symbol (you can replace this with a custom font path)
    final font = pw.Font.ttf(await rootBundle.load('lib/assets/fonts/Roboto-Black.ttf'));

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
          // Header with Logo (optional)
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
                            '$custShop',
                            style: pw.TextStyle(
                              fontSize: 42, // Larger font for emphasis
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#008080'), // Teal color
                              font: font,
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
                            font: font,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          pw.SizedBox(height: 20),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
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
                                'Owner Name: ',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  font: font,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Text(
                                '$custName',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: font,
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
                                  font: font,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Text(
                                '$custShop',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: font,
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
                                  font: font,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  '$custAddr',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    font: font,
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
                                  font: font,
                                  color: PdfColor.fromHex('#008080'),
                                ),
                              ),
                              pw.Text(
                                '$custMobile',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: font,
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
          pw.Text(
          'Billed To : $customerName',
          style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF004D40), // Dark Teal color
          font: font,  // Use the custom font
          ),
          ),
          pw.Divider(color: PdfColors.grey),
          pw.SizedBox(height: 10),

          // Bill Details (Tabular structure)
          pw.Table(
          border: pw.TableBorder.all(width: 1, color: PdfColors.grey),
          children: [
          // Table Header Row with shading
          pw.TableRow(
          decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFF004D40), // Teal header
          ),
          children: [
          pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.white, font: font)),
          ),
          pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.white, font: font)),
          ),
          pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.white, font: font)),
          ),
          pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.white, font: font)),
          ),
          ],
          ),

          // Table Data Rows with alternating row colors
          ...billItems.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return pw.TableRow(
          decoration: pw.BoxDecoration(
          color: index.isEven ? PdfColor.fromInt(0xFFE0F2F1) : PdfColor.fromInt(0xFFB2DFDB), // Light teal rows
          ),
          children: [
          pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text('${item['itemName']}', style: pw.TextStyle(fontSize: 14, font: font)),
          ),
          pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text('${item['quantity']}', style: pw.TextStyle(fontSize: 14, font: font)),
          ),
          pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text('₹${item['price']}', style: pw.TextStyle(fontSize: 14, font: font)), // ₹ should render properly now
          ),
          pw.Padding(
          padding: const pw.EdgeInsets.all(8.0),
          child: pw.Text('₹${item['itemTotal']}', style: pw.TextStyle(fontSize: 14, font: font)), // ₹ should render properly now
          ),
          ],
          );
          }).toList(),
          ],
          ),

          // Divider between bill items and total amount
          pw.Divider(color: PdfColors.grey),
          pw.SizedBox(height: 10),

          // Total Amount Section with Teal Accent
          pw.Text(
          'Total Amount: ₹$totalAmount',
          style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF00796B), // Teal color
          font: font,  // Use the custom font
          ),
          ),

          // Footer with Date and Time
          pw.SizedBox(height: 20),
          pw.Text(
          'Generated on: $formattedDay, $formattedDate at $formattedTime',
          style: pw.TextStyle(fontSize: 12, color: PdfColor.fromInt(0xFF004D40), font: font), // Teal footer text
          ),
          pw.SizedBox(height: 10),

          // Thank You Message in Footer with Teal
          pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(fontSize: 14, color: PdfColor.fromInt(0xFF00796B), font: font), // Teal footer message
          ),
          ),
          ],
          );
          },
      ),
    );

    // Save PDF to device storage
    final appDocDir = await getApplicationDocumentsDirectory();
    final beplusDir = Directory('${appDocDir.path}/BEplus');
    if (!await beplusDir.exists()) {
      await beplusDir.create(recursive: true);
    }
    final filePath = "${beplusDir.path}/bill_$customerName.pdf";
    final file = File(filePath);
    if (await file.exists()) {
      print("File already exists at: $filePath");
    } else {
      // Save the PDF content to the file.
      await file.writeAsBytes(await pdf.save());
      print("PDF saved successfully at: $filePath");
    }
    // Display the dialog with a download and share button
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Increased border radius for a smoother look
          ),
          elevation: 12, // Elevated shadow for better depth
          child: Padding(
            padding: const EdgeInsets.all(20.0), // Increased padding for spacious design
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Section
                Text(
                  'Generated Bill',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 12),
                Divider(thickness: 2, color: Colors.blueGrey.shade200),
                SizedBox(height: 12),

                // Customer Name
                Text(
                  'Customer Name: $customerName',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[700],
                  ),
                ),
                SizedBox(height: 16),

                // Bill Items List
                Column(
                  children: billItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Item Name
                          Text(
                            '${item['itemName']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          // Item Quantity, Price, and Total
                          Text(
                            'Qty: ${item['quantity']} - \₹${item['price']} - \₹${item['itemTotal']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Divider(thickness: 2, color: Colors.blueGrey.shade200),

                // Total Amount Section
                SizedBox(height: 12),
                Text(
                  'Total Amount: \₹$totalAmount',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 24),

                // Action Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Download Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Open the generated PDF file
                          await OpenFile.open(file.path);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.download, color: Colors.white),
                        label: Text(
                          'Download Bill',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    // Share Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Share the generated PDF file using XFile
                          final result = await Share.shareXFiles(
                              [XFile(file.path)],
                              text: 'Here is the generated bill for $customerName generated on $formattedDay, $formattedDate at $formattedTime.');

                          // Check the status of the share operation
                          if (result.status == ShareResultStatus.success) {
                            print('Thank you for sharing the bill!');
                          } else {
                            print('Failed to share the bill.');
                          }

                          // Close the dialog
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.share, color: Colors.white),
                        label: Text(
                          'Share Bill',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('                Bill Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade200, Colors.teal.shade900],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(  // Make the entire screen scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input Section
              TextField(
                controller: itemNameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'Enter the item name',
                  labelStyle: TextStyle(color: Colors.teal), // Label color in teal
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal, width: 2), // Teal focus line
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: Icon(Icons.shopping_bag, color: Colors.teal), // Teal icon color
                ),
              ),

              SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'Enter quantity',
                        labelStyle: TextStyle(color: Colors.teal), // Label color in teal
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2), // Teal focus line
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.format_list_numbered, color: Colors.teal), // Teal icon color
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        hintText: 'Enter price',
                        labelStyle: TextStyle(color: Colors.teal), // Label color in teal
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2), // Teal focus line
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.teal), // Teal icon color
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              TextField(
                controller: sizeController,
                decoration: InputDecoration(
                  labelText: 'Size',
                  hintText: 'Enter size of the product',
                  labelStyle: TextStyle(color: Colors.teal), // Label color in teal
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal, width: 2), // Teal focus line
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: Icon(Icons.crop_square, color: Colors.teal), // Teal icon color
                ),
              ),

              SizedBox(height: 10),

              TextField(
                controller: taxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tax (%)',
                  hintText: 'Enter tax percentage',
                  labelStyle: TextStyle(color: Colors.teal), // Label color in teal
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal, width: 2), // Teal focus line
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: Icon(Icons.percent, color: Colors.teal), // Teal icon color
                ),
                onChanged: (_) => updateTaxRate(), // Recalculate tax on every change
              ),

              SizedBox(height: 20),
              Center(
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: addItem,
                    borderRadius: BorderRadius.circular(30),
                    splashColor: Colors.teal.shade100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade700, Colors.teal.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Add Item',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Summary Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: Colors.teal.shade200,
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            '\₹${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.teal.shade100, thickness: 1, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tax',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            '\₹${calculateTax().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.teal.shade100, thickness: 1, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grand Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          Text(
                            '\₹${calculateGrandTotal().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Bill Items Section
              Text(
                'Bill Items:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Column(
                children: billItems.isEmpty
                    ? [Center(child: Text('No items added yet.'))]
                    : billItems.map((item) {
                  int index = billItems.indexOf(item);
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(item['itemName']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity: ${item['quantity']}, Price: \₹${item['price']}, Total: \₹${item['itemTotal']}',
                          ),
                          SizedBox(height: 5), // Add some spacing
                          Text(
                            'Size: ${item['size']}',
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade600),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => removeItem(index),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (billItems.isNotEmpty) // Add the 'Generate Bill' button if items are not empty
                Center(
                  child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      generateBill();
                    },
                    child: Text(
                      'Generate Bill',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Enhanced text style
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.teal, // Text color
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Adjust padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // Rounded corners
                      ),
                      elevation: 5, // Shadow for the button
                      shadowColor: Colors.black.withOpacity(0.2), // Custom shadow color
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600, // More emphasis on the text
                      ),
                    ),
                  ),
                ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
