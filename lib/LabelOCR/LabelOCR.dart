import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'database_helper.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:isolate';
import 'text_bucketing.dart';

class LabelOCR extends StatefulWidget {
  @override
  _LabelOCRState createState() => _LabelOCRState();
}

// Preprocessing function that will run in another isolate
void applyPreprocessingIsolate(Map<String, dynamic> message) async {
  final String imagePath = message['data'];
  final SendPort sendPort = message['port'];

  img.Image image = img.decodeImage(File(imagePath).readAsBytesSync())!;

  print("original width = ${image.width}");
  print("original height = ${image.height}");

  int newWidth = (image.width * 1.23).round();
  int newHeight = (image.height * 1.5).round();

  // Resize the image - optimal text height for OCR is 20-32 pixels
  image = img.copyResize(image, height: newHeight, width: newWidth);

  // Apply preprocessing to increase the contrast
  image = img.adjustColor(image, contrast: 2.69);

  // Convert the image to grayscale
  image = img.grayscale(image);

  // Convert the processed image back to a file
  final List<int> processedImageBytes = img.encodeJpg(image);
  final processedImageFile = File(imagePath)
    ..writeAsBytesSync(processedImageBytes);

  // Send processed image file path back to main isolate
  sendPort.send(processedImageFile.path);
}

class _LabelOCRState extends State<LabelOCR> {
  final ValueNotifier<String> _extractedTextNotifier =
      ValueNotifier<String>('');
  bool _isLoading = false;
  bool _isSaved = false;
  final ValueNotifier<File?> _croppedImageNotifier = ValueNotifier<File?>(null);
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Future<File?> _cropImage(File originalImageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: originalImageFile.path,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color.fromARGB(255, 8, 9, 10),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> saveExtractedText(String text) async {
    String timestamp = DateTime.now().toString();
    Map<String, dynamic> row = {
      DatabaseHelper.columnTimestamp: timestamp,
      DatabaseHelper.columnText: text,
    };
    int id = await DatabaseHelper.instance.insert(row);

    //To be removed (for testing purposes only)
    print("Inserted row with ID: $id");
  }

// Function to start the isolate and get the result
  Future<File> applyPreprocessing(String imagePath) async {
    // Create a port to receive the message from the isolate
    final receivePort = ReceivePort();

    // Start the isolate
    await Isolate.spawn(
      applyPreprocessingIsolate,
      {'data': imagePath, 'port': receivePort.sendPort},
    );

    // Wait for the processed image file path
    final processedImageFilePath = await receivePort.first as String;

    // Return the File object
    return File(processedImageFilePath);
  }

  Future<void> _readTextFromImage(ImageSource source) async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      File originalImageFile = File(pickedFile.path);
      File? croppedImageFile = await _cropImage(originalImageFile);
      _croppedImageNotifier.value = croppedImageFile;

      if (croppedImageFile != null) {
        final processedImageFile =
            await applyPreprocessing(croppedImageFile.path);

        // Create an InputImage instance from the processed image file
        final inputImage = InputImage.fromFilePath(processedImageFile.path);

        final textRecognizer = GoogleMlKit.vision.textRecognizer();
        RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        // Process text into buckets
        TextBucketing textBucketing = TextBucketing();
        String processedText =
            textBucketing.processExtractedText(recognizedText.toString());

        _extractedTextNotifier.value = processedText;
        _textEditingController.text = processedText;

        textRecognizer.close();
      }
    }

    setState(() {
      _isLoading = false; // Set loading state
    });
  }

  @override
  void dispose() {
    _extractedTextNotifier.dispose();
    _croppedImageNotifier.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          buttonTheme: const ButtonThemeData(
            buttonColor: Colors.blue, //  <-- dark color
            textTheme: ButtonTextTheme.primary,
          ),
        ),
        home: GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus(); // dismiss keyboard
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Label OCR'),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () =>
                              _readTextFromImage(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32.0),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: const Text('Capture Image'),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _readTextFromImage(ImageSource.gallery),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32.0),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Text('Upload Image'),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Extracted Text:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 400,
                          height: 150,
                          child: ValueListenableBuilder<String>(
                            valueListenable: _extractedTextNotifier,
                            builder: (context, value, child) {
                              if (value.isNotEmpty &&
                                  _textEditingController.text.isEmpty) {
                                _textEditingController.text = value;
                                _isSaved = false;
                              }
                              return _textEditingController.text.isEmpty
                                  ? _isLoading
                                      ? const Center(
                                          child: Text("Extracting text..."))
                                      : const Center(
                                          child: Text("No text extracted"))
                                  : SingleChildScrollView(
                                      child: TextField(
                                        controller: _textEditingController,
                                        focusNode: _focusNode,
                                        maxLines: null,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                            },
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text(
                          'Cropped Image:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton(
                          onPressed: _isSaved
                              ? null
                              : () {
                                  saveExtractedText(
                                      _textEditingController.text);
                                  setState(() {
                                    _isSaved = true;
                                  });
                                },
                          child: const Text('Save Text'),
                        ),
                      ],
                    ),
                    Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 400,
                          height: 150,
                          child: ValueListenableBuilder<File?>(
                            valueListenable: _croppedImageNotifier,
                            builder: (context, file, child) {
                              if (file != null) {
                                return Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                );
                              } else {
                                return const Center(
                                    child: Text('No image selected'));
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
