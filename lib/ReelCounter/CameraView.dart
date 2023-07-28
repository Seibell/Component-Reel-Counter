import 'dart:io';
import 'package:component_reel_counter/ReelCounter/DrawEntireBoxScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  File? _imageFile;
  final picker = ImagePicker();

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _takePictureAndEdit() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final originalImageFile = File(pickedFile.path);
    if (originalImageFile == null) return;

    // Convert the image to JPEG
    final jpgBytes = await FlutterImageCompress.compressWithFile(
      originalImageFile.absolute.path,
      format: CompressFormat.jpeg,
    );

    if (jpgBytes == null) {
      print('Image compression failed');
      return;
    }

    final jpgImage = File(originalImageFile.path.replaceFirst('.heic', '.jpg'));
    await jpgImage.writeAsBytes(jpgBytes);

    _imageFile = jpgImage;
    setState(() {});

    // Pass the cropped image file to the EditPictureScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawEntireBoxScreen(
          imageFile: XFile(jpgImage.path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _imageFile != null
          ? Image.file(_imageFile!)
          : Center(child: Text('No Image Selected')),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePictureAndEdit,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
