import 'dart:io';
import 'package:component_reel_counter/ReelCounter/DrawEntireBoxScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

    _imageFile = originalImageFile;
    setState(() {});

    // Pass the cropped image file to the EditPictureScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawEntireBoxScreen(
          imageFile: XFile(originalImageFile.path),
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
