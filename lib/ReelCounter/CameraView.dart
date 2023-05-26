import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'EditPictureScreen.dart';

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late Future<void> _initializeControllerFuture;

  late CameraController controller;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    _initializeControllerFuture = controller.initialize();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<XFile> takePicture() async {
    if (!controller.value.isInitialized) {
      print('Error: select a camera first.');
      throw Exception('select a camera first.');
    }

    if (controller.value.isTakingPicture) {
      print('Error: processing is in progress.');
      throw Exception('processing is in progress.');
    }

    try {
      XFile file = await controller.takePicture();
      return file;
    } on CameraException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.description}');
      throw e;
    }
  }

  Future<void> takePictureAndEdit() async {
    try {
      final imageFile = await takePicture();

      // Navigate to a new screen, passing the picture file
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPictureScreen(imageFile: imageFile),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              Positioned.fill(
                child: CameraPreview(controller),
              ),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: takePictureAndEdit,
                  child: Icon(Icons.camera),
                ),
              ),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
