import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
class BillRecognition extends StatefulWidget {
  const BillRecognition({Key? key}) : super(key: key);

  @override
  State<BillRecognition> createState() => _BillRecognitionState();
}

class _BillRecognitionState extends State<BillRecognition> {
  bool textScanning = false;
  XFile? imageFile;
  String scannedText = "";
  String recognizedText = '';
  Map<String, String> billDetails = {};
  List<Map<String, dynamic>> extractedItems = []; // Store extracted items
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        title: const Text("Bill Recognition", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (textScanning)
                  const CircularProgressIndicator(color: Colors.teal),
                if (!textScanning && imageFile == null)
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      // Add gradient background
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade200, Colors.teal.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20), // More rounded corners
                      border: Border.all(color: Colors.tealAccent, width: 3), // Subtle border with accent color
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26, // Subtle shadow for depth
                          blurRadius: 10,
                          offset: Offset(5, 5), // Shadow offset
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported, // Icon representing no image
                          size: 50,
                          color: Colors.white70, // Light color for the icon
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No Image Selected",
                          style: TextStyle(
                            color: Colors.white, // White text color
                            fontSize: 18, // Slightly larger text
                            fontWeight: FontWeight.bold, // Bold text for emphasis
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Tap to select an image",
                          style: TextStyle(
                            color: Colors.white70, // Lighter text for secondary info
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15), // Rounded corners
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15), // Keep the same rounded corners
                        border: Border.all(color: Colors.tealAccent, width: 3), // Light accent border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26, // Subtle shadow for depth
                            blurRadius: 10,
                            offset: Offset(4, 4), // Slight offset for shadow
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15), // Keep consistent border radius
                        child: Image.file(
                          File(imageFile!.path),
                          fit: BoxFit.cover, // Ensures the image covers the area without distortion
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildButton(
                      icon: Icons.image,
                      label: "Gallery",
                      onPressed: () => getImage(ImageSource.gallery),
                      backgroundColor: Colors.teal, // Color for button background
                      iconColor: Colors.white, // Icon color
                      labelColor: Colors.white, // Text color
                      borderRadius: 30.0, // Rounded corners for buttons
                    ),
                    const SizedBox(width: 20), // Increased space between buttons
                    buildButton(
                      icon: Icons.camera_alt,
                      label: "Camera",
                      onPressed: () => getImage(ImageSource.camera),
                      backgroundColor: Colors.orange, // Different color for variety
                      iconColor: Colors.white,
                      labelColor: Colors.white,
                      borderRadius: 30.0,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (billDetails.isNotEmpty)
                  Card(
                    elevation: 4, // Add subtle shadow for depth
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal, // Highlight header
                            ),
                          ),
                          const SizedBox(height: 15),
                          Divider(color: Colors.grey.shade300), // Subtle divider below the header
                          buildDetailRow("Shop Name:", billDetails['shopName'] ?? "N/A"),
                          buildDetailRow("Owner Name:", billDetails['ownerName'] ?? "N/A"),
                          buildDetailRow("Billed To:", billDetails['billedTo'] ?? "N/A"),
                          buildDetailRow("Total Amount:", billDetails['totalAmount'] ?? "N/A"),
                          buildDetailRow("Date:", billDetails['date'] ?? "N/A"),
                          buildDetailRow("Mobile Number:", billDetails['mobile'] ?? "N/A"),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (extractedItems.isNotEmpty)
                  Card(
                    elevation: 4, // Add subtle shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Items:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal, // Highlighted color
                            ),
                          ),
                          const SizedBox(height: 15),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: extractedItems.length,
                            separatorBuilder: (context, index) => const Divider(
                              color: Colors.grey, // Add divider between items
                            ),
                            itemBuilder: (context, index) {
                              var item = extractedItems[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.shopping_bag, size: 20, color: Colors.teal), // Icon for items
                                        const SizedBox(width: 10),
                                        Text(
                                          item['name'],
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${item['quantity']} x \$${item['price']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    required Color labelColor,
    required double borderRadius,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor, // Set background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius), // Round corners
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25), // Add padding
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor), // Icon color customization
          const SizedBox(width: 10), // Space between icon and label
          Text(
            label,
            style: TextStyle(
              color: labelColor, // Label text color customization
              fontSize: 16,
              fontWeight: FontWeight.bold, // Bold text for better visibility
            ),
          ),
        ],
      ),
    );
  }
  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          textScanning = true;
          imageFile = pickedImage;
        });
        await getRecognizedText(pickedImage);
        setState(() {
          textScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        textScanning = false;
        imageFile = null;
        scannedText = "Error occurred while scanning";
      });
    }
  }

  Future<void> getRecognizedText(XFile image) async {
    // Create an InputImage object from the file path
    final inputImage = InputImage.fromFilePath(image.path);

    // Create the Text Recognizer
    final textDetector = TextRecognizer();

    try {
      // Process the image and get recognized text
      final RecognizedText recognizedText = await textDetector.processImage(inputImage);

      // Close the text recognizer (clean up resources)
      await textDetector.close();

      // Recognize text from the image and pass it to the other functions
      await recognizeText(image);

      // Save the entire recognized text for debugging
      final scannedText = recognizedText.text;
      print("Scanned Text: $scannedText");

      // Clear existing bill details
      billDetails.clear();
      extractedItems.clear();

      // Extract specific details from the text
      extractBillDetails(scannedText);

      // Extract table contents (items) from the text
      extractItemsFromText(scannedText);

    } catch (e) {
      print("Error during text recognition: $e");
    } finally {
      // Make sure the text recognizer is closed in the finally block
      await textDetector.close();
    }
  }


  // Extract specific bill details from the text
  void extractBillDetails(String scannedText) {
    List<String> lines = scannedText.split('\n');

    String? shopName, ownerName, billedTo, date, totalAmount, mobile;

    for (String line in lines) {
      final text = line.trim();

      if (text.startsWith("Shop Name:")) {
        shopName = extractValue(text);
      } else if (text.startsWith("Owner Name:")) {
        ownerName = extractValue(text);
      } else if (text.startsWith("Billed To:")) {
        billedTo = extractValue(text);
      } else if (text.startsWith("Total Amount")) {
        totalAmount = extractValue(text);
      } else if (text.startsWith("Date:")) {
        date = extractValue(text);
      } else if (text.startsWith("Mobile Number:")) {
        mobile = extractValue(text);
      }
    }

    // Fill in the bill details map
    if (shopName != null) billDetails['shopName'] = shopName;
    if (ownerName != null) billDetails['ownerName'] = ownerName;
    if (billedTo != null) billDetails['billedTo'] = billedTo;
    if (totalAmount != null) billDetails['totalAmount'] = totalAmount;
    if (date != null) billDetails['date'] = date;
    if (mobile != null) billDetails['mobile'] = mobile;

    print("Extracted Bill Details: $billDetails");
  }

  // Extract table contents (items) from the text
  void extractItemsFromText(String scannedText) {
    List<String> lines = scannedText.split('\n');
    List<String> items = [];
    List<String> quantities = [];
    List<String> prices = [];

    bool isItemSection = false;
    bool isQuantitySection = false;
    bool isPriceSection = false;

    for (String line in lines) {
      line = line.trim();

      // Start capturing items after 'Item Name' and until 'Date' or 'Quantity'
      if (line.contains('Item Name')) {
        isItemSection = true;
        continue;
      }
      if (isItemSection && (line.contains('Date') || line.contains('Quantity'))) {
        isItemSection = false;
      }
      if (isItemSection && line.isNotEmpty) {
        items.add(line);
      }

      // Start capturing quantities after 'Quantity' and until 'Total Amount' or 'Price'
      if (line.contains('Quantity')) {
        isQuantitySection = true;
        continue;
      }
      if (isQuantitySection && (line.contains('Total Amount') || line.contains('Price'))) {
        isQuantitySection = false;
      }
      if (isQuantitySection && line.isNotEmpty) {
        quantities.add(line);
      }

      // Start capturing prices after 'Generated on' and until 'Thank you'
      if (line.contains('Generated on')) {
        isPriceSection = true;
        continue;
      }
      if (isPriceSection && line.contains('Thank you')) {
        isPriceSection = false;
      }
      if (isPriceSection && line.isNotEmpty) {
        prices.add(line);
      }
    }

    // Combine extracted data into a structured format
    extractedItems.clear();
    for (int i = 0; i < items.length; i++) {
      extractedItems.add({
        'name': items[i],
        'quantity': i < quantities.length ? int.tryParse(quantities[i]) : null,
        'price': i < prices.length ? double.tryParse(prices[i]) : null,
      });
    }

    print("Extracted Items: $extractedItems");
  }

  // Helper function to extract values after a colon ":"
  String extractValue(String text) {
    final parts = text.split(":");
    return parts.length > 1 ? parts[1].trim() : "N/A";
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> recognizeText(XFile image) async {
    setState(() {
      textScanning = true; // Show progress indicator while recognizing text
    });

    print('Started text recognition...'); // Debugging: Log when recognition starts

    try {
      // Log the image path for debugging
      print('Processing image: ${image.path}');

      // Check if the image exists (you can use `existsSync` method)
      final file = File(image.path);
      if (!file.existsSync()) {
        print('Image file does not exist at ${image.path}');
        setState(() {
          recognizedText = 'Image file does not exist';
          textScanning = false;
        });
        return;
      }

      // Recognize text using Tesseract OCR
      String text = await FlutterTesseractOcr.extractText(image.path);

      // Debugging: Log the recognized text (only a portion to avoid large logs)
      print('Recognized Text: ${text.substring(0, text.length > 100 ? 100 : text.length)}'); // Show first 100 characters

      // Update UI with recognized text
      setState(() {
        recognizedText = text; // Store the recognized text
        textScanning = false; // Hide the progress indicator
      });
    } catch (e) {
      // Log the error message for debugging
      print('Error occurred: $e'); // Debugging: Log the error message

      setState(() {
        recognizedText = 'Error recognizing text: $e'; // Display the error message
        textScanning = false;
      });
    }
  }



}
