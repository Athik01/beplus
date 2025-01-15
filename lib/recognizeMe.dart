import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ocr_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
class RecognizeMeApp extends StatefulWidget {
  @override
  _RecognizeMeAppState createState() => _RecognizeMeAppState();
}

class _RecognizeMeAppState extends State<RecognizeMeApp> {
  File? _image;
  String _recognizedText = "";
  bool _isRecognizing = false;
  final OcrService _ocrService = OcrService();
  String custName = "";
  String custShop = "";
  String custAddr = "";
  String custMobile = "";
  // Text editing controllers for input fields
  TextEditingController taxController = TextEditingController();

  List<TextEditingController> nameControllers = [];
  List<TextEditingController> quantityControllers = [];
  List<TextEditingController> priceControllers = [];
  @override
  void initState() {
    super.initState();
  }
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _recognizedText = "";
        _isRecognizing = true;
      });

      // Perform text recognition
      String result = await _recognizeText(pickedFile.path);

      setState(() {
        _recognizedText = result;
        _isRecognizing = false;
      });
    }
  }

  Future<String> _recognizeText(String imagePath) async {
    try {
      final text = await _ocrService.recognizeHandwrittenText(File(imagePath));
      return text.isNotEmpty ? text : "No handwritten text found.";
    } catch (e) {
      print("Error during text recognition: $e");
      return "Text recognition failed.";
    }
  }

  List<List<String>> _parseRecognizedText(String text) {
    List<List<String>> parsedData = [];
    List<String> lines = text.split('\n');
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      List<String> parts = line.split(RegExp(r'[,\-/.]')).map((e) => e.trim()).toList();
      String name = parts.isNotEmpty ? parts[0] : "";
      String quantity = parts.length > 1 ? parts[1] : "";
      String price = parts.length > 2 ? parts[2] : "";
      parsedData.add([name, quantity, price]);
    }
    return parsedData;
  }

  Future<Map<String, dynamic>> fetchUserData(String ownerId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return {}; // return an empty map if user not found
    }
  }
  Future<void> _generate() async{
    String customerName = '';
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
                          _generateBill(customerName);
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

  Future<void> _generateBill(String customerName) async {
    final font = pw.Font.ttf(await rootBundle.load('lib/assets/fonts/Roboto-Black.ttf'));
    if (taxController.text.isEmpty || double.tryParse(taxController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid tax percentage")));
      return;
    }

    double taxPercentage = double.parse(taxController.text);

    // Check if any product fields are empty
    for (int i = 0; i < nameControllers.length; i++) {
      if (nameControllers[i].text.isEmpty ||
          quantityControllers[i].text.isEmpty ||
          priceControllers[i].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill out all fields for every product")));
        return;
      }
    }
    String ownerId = FirebaseAuth.instance.currentUser!.uid;
    Future<Map<String, dynamic>> fetchUserData(String ownerId) async {
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
    await fetchUserData(ownerId).then((userData) {
      custMobile = userData['mobile'] ?? 'Not Available';
      custName = userData['name'] ?? 'Not Available';
      custAddr = userData['address'] ?? 'Not Available';
      custShop = userData['shopName'] ?? 'Shop';
    });
    // Calculate the total, tax, and final total
    double totalAmount = 0;
    for (int i = 0; i < nameControllers.length; i++) {
      double price = double.parse(priceControllers[i].text);
      int quantity = int.parse(quantityControllers[i].text);
      double amount = price * quantity;
      totalAmount += amount;
    }
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('hh:mm:ss a').format(now);
    String formattedDay = DateFormat('EEEE').format(now);
    double taxAmount = (totalAmount * taxPercentage) / 100;
    double finalAmount = totalAmount + taxAmount;

    // Display the generated bill
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
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
              // Customer Details
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

              // Bill Items Table
              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.grey),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#004D40')),
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
                  ...nameControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    var itemName = nameControllers[index].text;
                    var quantity = int.parse(quantityControllers[index].text);
                    var price = double.parse(priceControllers[index].text);
                    var total = price * quantity;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index.isEven ? PdfColor.fromHex('#E0F2F1') : PdfColor.fromHex('#B2DFDB'),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(itemName, style: pw.TextStyle(fontSize: 14, font: font)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('$quantity', style: pw.TextStyle(fontSize: 14, font: font)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('₹$price', style: pw.TextStyle(fontSize: 14, font: font)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('₹$total', style: pw.TextStyle(fontSize: 14, font: font)),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 10),
              // Total Summary
              pw.Text(
                'Total: ₹$totalAmount',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#004D40'), font: font),
              ),
              pw.Text(
                'Tax: ₹$taxAmount',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#004D40'), font: font),
              ),
              pw.Text(
                'Final Total: ₹$finalAmount',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#004D40'), font: font),
              ),
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


    // Save PDF to local storage
    final appDocDir = await getApplicationDocumentsDirectory();
    final beplusDir = Directory('${appDocDir.path}/BEplus');
    if (!await beplusDir.exists()) {
      await beplusDir.create(recursive: true);
    }
    final filePath = "${beplusDir.path}/bill_of_$customerName.pdf";
    final file = File(filePath);
    if (await file.exists()) {
      print("File already exists at: $filePath");
    } else {
      // Save the PDF content to the file.
      await file.writeAsBytes(await pdf.save());
      print("PDF saved successfully at: $filePath");
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Bill Saved"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Bill for $customerName has been saved successfully.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
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
                    text: 'Here is the generated bill for $customerName.',
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
      );
    },
    );
  }
  @override
  Widget build(BuildContext context) {
    List<List<String>> products = _recognizedText.isNotEmpty ? _parseRecognizedText(_recognizedText) : [];

    // Initialize controllers for each product
    if (products.isNotEmpty) {
      nameControllers = products.map((product) => TextEditingController(text: product[0])).toList();
      quantityControllers = products.map((product) => TextEditingController(text: product[1])).toList();
      priceControllers = products.map((product) => TextEditingController(text: product[2])).toList();
    }

    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.teal),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the Row content
            children: [
              Icon(Icons.text_fields, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Bill Recognition",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 5,
          centerTitle: true, // Ensures the title is centered in the AppBar
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _image == null
                    ? GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: _buildImagePlaceholder(),
                )
                    : _buildSelectedImage(),
                SizedBox(height: 30),
                if (_isRecognizing)
                  CircularProgressIndicator(color: Colors.teal)
                else if (products.isNotEmpty)
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 500),
                    opacity: _recognizedText.isNotEmpty ? 1 : 0,
                    child: _buildDynamicInputFields(products),
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showImagePicker(context),
          child: Icon(Icons.add),
          backgroundColor: Colors.tealAccent.shade400,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 270,
      width: 270,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Colors.teal, size: 60),
            SizedBox(height: 15),
            Text(
              "Tap to Select an Image",
              style: TextStyle(
                color: Colors.teal,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Container(
      height: 270,
      width: 270,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          _image!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDynamicInputFields(List<List<String>> products) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag,
                  color: Colors.teal.shade800,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  "Products",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                    shadows: [
                      Shadow(
                        color: Colors.teal.shade300,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          ...products.asMap().entries.map((entry) {
            int index = entry.key;
            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameControllers[index],
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.shopping_cart, color: Colors.teal),
                              labelText: "Item Name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: quantityControllers[index],
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.numbers, color: Colors.teal),
                              labelText: "Quantity",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceControllers[index],
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.attach_money, color: Colors.teal),
                              labelText: "Price",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          SizedBox(height: 20),
          // Tax input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: taxController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.percent, color: Colors.teal),
                    labelText: "Tax Percentage (%)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _generate,
              icon: Icon(Icons.receipt, color: Colors.white),
              label: Text("Generate Bill",style: TextStyle(color:Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListTile(
            leading: Icon(Icons.photo, color: Colors.teal),
            title: Text("Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        );
      },
    );
  }
}
