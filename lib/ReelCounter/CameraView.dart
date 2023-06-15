import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import './EditPictureScreen.dart';

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  File? _imageFile;
  final picker = ImagePicker();

  Future<void> _takePictureAndEdit() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final originalImageFile = File(pickedFile.path);
    final croppedImageFile = await _cropImage(originalImageFile);
    if (croppedImageFile == null) return;

    final imageSize = await getImageSize(croppedImageFile.path, context);
    final double entireImageWidth = imageSize.width;
    final double entireImageHeight = imageSize.height;

    _imageFile = croppedImageFile;
    setState(() {});

    // Pass the cropped image file to the EditPictureScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPictureScreen(
            imageFile: XFile(croppedImageFile.path),
            imageWidth: entireImageWidth,
            imageHeight: entireImageHeight),
      ),
    );
  }

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

  Future<ui.Size> getImageSize(String path, BuildContext context) async {
    final data = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frameInfo = await codec.getNextFrame();

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Size(
      frameInfo.image.width.toDouble() / devicePixelRatio,
      frameInfo.image.height.toDouble() / devicePixelRatio,
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
