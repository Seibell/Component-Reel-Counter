import 'dart:io';
import 'package:component_reel_counter/ReelCounter/DrawEntireBoxScreen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  File? _imageFile;
  List<CameraDescription>? cameras;
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras![0], ResolutionPreset.medium);
    await controller!.initialize();
  }

  Future<void> _takePictureAndEdit() async {
    if (!controller!.value.isInitialized) {
      return;
    }
    final XFile? photo = await controller!.takePicture();

    if (photo == null) return;

    final originalImageFile = File(photo.path);
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
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

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
