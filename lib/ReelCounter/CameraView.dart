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
  Future<void>? _initializeCameraFuture;

  @override
  void initState() {
    super.initState();
    _initializeCameraFuture = initializeCamera();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras![0], ResolutionPreset.ultraHigh);
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
    return FutureBuilder<void>(
      future: _initializeCameraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Always display the preview.
          return Scaffold(
            body: CameraPreview(controller!),
            floatingActionButton: FloatingActionButton(
              onPressed: _takePictureAndEdit,
              child: Icon(Icons.camera_alt),
            ),
          );
        } else {
          // Otherwise, display a loading indicator.
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
