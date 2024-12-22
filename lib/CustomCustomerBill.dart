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

    // Show Dialog to get the customer's name
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
                        if (customerName.isNotEmpty) {
                          showGeneratedBill(customerName);
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
    billItems.forEach((item) {
      totalAmount += item['itemTotal'];
    });

    // Get current date and time
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);
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
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
          pw.Text(
          'Generated Bill',
          style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF00796B), // Teal color
          font: font,  // Use the custom font
          ),
          ),
          ],
          ),
          pw.SizedBox(height: 20),

          // Customer Name
          pw.Text(
          'Customer: $customerName',
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
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/bill_$customerName.pdf");
    await file.writeAsBytes(await pdf.save());

    // Display the dialog with a download and share button
    showDialog(
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
              children: [
                Text(
                  'Generated Bill',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Customer Name: $customerName',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                Divider(),
                SizedBox(height: 10),
                // Displaying the bill items with better styling
                ...billItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['itemName']}',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          'Qty: ${item['quantity']} - \₹${item['price']} - \₹${item['itemTotal']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                Divider(),
                SizedBox(height: 10),
                Text(
                  'Total Amount: \₹$totalAmount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 20),
                // Download button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Download Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0), // Vertical padding between buttons
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Open the generated PDF file
                          await OpenFile.open(file.path);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.download, color: Colors.white), // Icon for Download
                        label: Text(
                          'Download Bill',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    // Share Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0), // Vertical padding between buttons
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Share the generated PDF file using XFile
                          final result = await Share.shareXFiles(
                              [XFile(file.path)],
                              text: 'Here is the generated bill for $customerName generated on $formattedDay, $formattedDate at $formattedTime.'
                          );

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
                          padding: EdgeInsets.symmetric(horizontal: 29, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.share, color: Colors.white), // Icon for Share
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
