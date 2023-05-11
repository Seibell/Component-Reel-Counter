import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'database_helper.dart';

class LabelOCR extends StatefulWidget {
  @override
  _LabelOCRState createState() => _LabelOCRState();
}

class _LabelOCRState extends State<LabelOCR> {
  final ValueNotifier<String> _extractedTextNotifier =
      ValueNotifier<String>('');
  bool _isLoading = false; // Added variable to track loading state

  Future<void> saveExtractedText(String text) async {
    String timestamp = DateTime.now().toString();
    Map<String, dynamic> row = {
      DatabaseHelper.columnTimestamp: timestamp,
      DatabaseHelper.columnText: text,
    };
    int id = await DatabaseHelper.instance.insert(row);

    // To be removed (for testing purposes only)
    print("Inserted row with ID: $id");
  }

  Future<File> applyPreprocessing(String imagePath) async {
    img.Image image = img.decodeImage(File(imagePath).readAsBytesSync())!;

    // To be removed soon (for testing only)
    print("original width = ${image.width}");
    print("original height = ${image.height}");

    int newWidth = (image.width * 1.23).round();
    int newHeight = (image.height * 1.5).round();

    // Resize the image - optimal text height for OCR is 20-32 pixels
    image = img.copyResize(image, height: newHeight, width: newWidth);
    // Apply Gaussian blur to the image
    // image = img.gaussianBlur(image, radius: 10);

    // Apply preprocessing to increase the contrast
    image = img.adjustColor(image, contrast: 2.69);

    // Convert the image to grayscale (optional)
    image = img.grayscale(image);

    // Convert the processed image back to a file
    final List<int> processedImageBytes = img.encodeJpg(image);
    final processedImageFile = File(imagePath)
      ..writeAsBytesSync(processedImageBytes);

    return processedImageFile;
  }

  Future<void> _readTextFromImage(ImageSource source) async {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final processedImageFile = await applyPreprocessing(pickedFile.path);

      // Create an InputImage instance from the processed image file
      final inputImage = InputImage.fromFilePath(processedImageFile.path);

      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      _extractedTextNotifier.value = recognizedText.text;
      await saveExtractedText(recognizedText.text);

      textRecognizer.close();
    }

    setState(() {
      _isLoading = false; // Hide loading spinner
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'Label OCR',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () => _readTextFromImage(ImageSource.camera),
          child: const Text('Capture Image and Read Text'),
        ),
        ElevatedButton(
          onPressed: () => _readTextFromImage(ImageSource.gallery),
          child: const Text('Upload Image and Read Text'),
        ),
        const SizedBox(height: 20),
        const Text(
          'Extracted Text:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(
          valueListenable: _extractedTextNotifier,
          builder: (context, value, child) {
            if (_isLoading) {
              return CircularProgressIndicator(); // Show loading spinner
            } else {
              return Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
