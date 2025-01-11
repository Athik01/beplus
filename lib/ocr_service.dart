import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

class OcrService {
  final String _apiKey = 'd51e83b273mshc84732abf348ebap1177c2jsne187797f8c50';
  final String _apiUrl = 'https://pen-to-print-handwriting-ocr.p.rapidapi.com/recognize/';

  /// Recognize handwritten text using Pen-to-Print Handwriting OCR API
  Future<String> recognizeHandwrittenText(File imageFile) async {
    try {
      // Resize and compress the image
      File resizedImageFile = await _resizeAndCompressImage(imageFile);

      // Create multipart request
      final uri = Uri.parse(_apiUrl);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['x-rapidapi-key'] = _apiKey;
      request.headers['x-rapidapi-host'] = 'pen-to-print-handwriting-ocr.p.rapidapi.com';

      // Add form fields
      request.fields['includeSubScan'] = '0';
      request.fields['Session'] = 'string';

      // Add the resized image file as multipart
      final imageBytes = await resizedImageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
          'srcImg',
          imageBytes,
          filename: resizedImageFile.path.split('/').last,
          contentType: MediaType('image', 'png')  // Adjust content type if needed
      );
      request.files.add(multipartFile);

      // Send the request
      final response = await request.send();

      // Check the response
      if (response.statusCode == 200) {
        final responseString = await response.stream.bytesToString();
        final responseData = json.decode(responseString);

        // Extract recognized text
        if (responseData['value'] != null) {
          return responseData['value'].toString().trim();
        } else {
          return 'No handwritten text recognized.';
        }
      } else {
        return 'Failed to connect to the API. Status Code: ${response.statusCode}';
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  /// Resize and compress the image to make it smaller and under 1MB
  Future<File> _resizeAndCompressImage(File imageFile) async {
    // Load the image
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) {
      throw Exception('Failed to decode image,Try with WhatsApp Cam!');
    }

    // Resize the image to a maximum width of 500px, maintaining the aspect ratio
    int maxWidth = 500;
    int width = image.width;
    int height = image.height;

    if (width > maxWidth) {
      double aspectRatio = height / width;
      height = (maxWidth * aspectRatio).toInt();
      width = maxWidth;
    }

    img.Image resizedImage = img.copyResize(image, width: width, height: height);

    // Save the resized image to a temporary file
    final tempFile = File('${Directory.systemTemp.path}/temp_image.png');
    await tempFile.writeAsBytes(img.encodePng(resizedImage));

    // Check the file size and compress if necessary
    int fileSize = await tempFile.length();
    if (fileSize > 1024 * 1024) { // Larger than 1MB
      // Compress the image further (e.g., reduce quality)
      img.Image compressedImage = img.copyResize(resizedImage); // Adjust quality as needed
      await tempFile.writeAsBytes(img.encodePng(compressedImage));
    }

    return tempFile;
  }
}
