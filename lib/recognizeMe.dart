import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'ocr_service.dart';

class RecognizeMeApp extends StatefulWidget {
  @override
  _RecognizeHandwrittenTextState createState() => _RecognizeHandwrittenTextState();
}

class _RecognizeHandwrittenTextState extends State<RecognizeMeApp> {
  File? _image;
  String _recognizedText = "No text recognized yet!";
  final OcrService _ocrService = OcrService();

  // Pick an image from the gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Recognize text in the image
      String result = await _recognizeText(pickedFile.path);
      setState(() {
        _recognizedText = result;
      });
    }
  }

  // Perform text recognition using OCR Space API
  Future<String> _recognizeText(String imagePath) async {
    try {
      // Initialize the OCR service
      final ocrService = OcrService();

      // Perform text recognition using the image path
      final text = await ocrService.recognizeHandwrittenText(File(imagePath));

      // Return the recognized text or a default message if empty
      return text.isNotEmpty ? text : "No handwritten text found.";
    } catch (e) {
      // Log the error for debugging purposes
      print("Error during text recognition: $e");

      // Return an error message
      return "Text recognition failed.";
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.teal),
      home: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.text_fields, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Text Recognition",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
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
        ),
        body: SingleChildScrollView( // Wrap the entire body with SingleChildScrollView
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image Display
                _image == null
                    ? GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    height: 270,
                    width: 270,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400,
                          blurRadius: 15,
                          spreadRadius: 5,
                          offset: Offset(6, 6),
                        ),
                      ],
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
                  ),
                )
                    : Container(
                  height: 270,
                  width: 270,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 15,
                        spreadRadius: 5,
                        offset: Offset(6, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.teal, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      height: 270,
                      width: 270,
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Recognized Text Display
                Text(
                  "Recognized Text",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.teal.shade900,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 15),
                Card(
                  elevation: 8,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: Colors.teal.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView( // Added scrollable functionality
                      child: Text(
                        _recognizedText,
                        textAlign: TextAlign.start, // Aligned text to the left for better readability
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.teal.shade900,
                          height: 1.5, // Added line height for better text spacing
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: FloatingActionButton(
            onPressed: () => _showImagePicker(context),
            child: Icon(Icons.add),
            backgroundColor: Colors.tealAccent.shade400,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo, color: Colors.teal),
                title: Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}