import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class LabelOCR extends StatefulWidget {
  @override
  _LabelOCRState createState() => _LabelOCRState();
}

class _LabelOCRState extends State<LabelOCR> {
  final ValueNotifier<String> _extractedTextNotifier =
      ValueNotifier<String>('');

  Future<void> _readTextFromImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      // Load the image file
      img.Image image =
          img.decodeImage(File(pickedFile.path).readAsBytesSync())!;

      // Apply preprocessing to increase the contrast
      image = img.adjustColor(image, contrast: 2.0);

      // Convert the processed image back to a file
      final List<int> processedImageBytes = img.encodeJpg(image);
      final processedImageFile = File(pickedFile.path)
        ..writeAsBytesSync(processedImageBytes);

      // Create an InputImage instance from the processed image file
      final inputImage = InputImage.fromFilePath(processedImageFile.path);

      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      _extractedTextNotifier.value = recognizedText.text;

      textRecognizer.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Label OCR',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () => _readTextFromImage(ImageSource.camera),
          child: Text('Capture Image and Read Text'),
        ),
        ElevatedButton(
          onPressed: () => _readTextFromImage(ImageSource.gallery),
          child: Text('Upload Image and Read Text'),
        ),
        SizedBox(height: 20),
        Text(
          'Extracted Text:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ValueListenableBuilder<String>(
          valueListenable: _extractedTextNotifier,
          builder: (context, value, child) {
            return Expanded(
              child: SingleChildScrollView(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
