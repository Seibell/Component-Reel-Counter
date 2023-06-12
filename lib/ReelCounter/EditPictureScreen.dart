import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:math';
import './ReelTypeForm.dart';

class EditPictureScreen extends StatefulWidget {
  final XFile imageFile;

  EditPictureScreen({required this.imageFile});

  @override
  _EditPictureScreenState createState() => _EditPictureScreenState();
}

class _EditPictureScreenState extends State<EditPictureScreen> {
  GlobalKey globalKey = GlobalKey();
  Offset topLeft = Offset(0, 0);
  Offset topRight = Offset(0, 0);
  Offset bottomLeft = Offset(0, 0);
  Offset bottomRight = Offset(0, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setInitialBoxCoordinates();
    });
  }

  void setInitialBoxCoordinates() {
    final screenSize = MediaQuery.of(context).size;
    final initialLength = screenSize.width * 0.4;
    final initialWidth = screenSize.height * 0.2;

    setState(() {
      topLeft = Offset(screenSize.width / 2 - initialLength / 2,
          screenSize.height / 2 - initialWidth / 2);
      topRight = Offset(screenSize.width / 2 + initialLength / 2,
          screenSize.height / 2 - initialWidth / 2);
      bottomLeft = Offset(screenSize.width / 2 - initialLength / 2,
          screenSize.height / 2 + initialWidth / 2);
      bottomRight = Offset(screenSize.width / 2 + initialLength / 2,
          screenSize.height / 2 + initialWidth / 2);
    });
  }

  void resetBoxCoordinates() {
    setInitialBoxCoordinates();
  }

  void _showReelTypeForm(double averageBoxDiagonalLengthInRealLifeInMM,
      Completer<void> completer) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ReelTypeForm(averageBoxDiagonalLengthInRealLifeInMM, completer);
      },
    );
  }

  double calculateAverageBoxLength() {
    final double length1 = (topLeft - topRight).distance;
    final double length2 = (topRight - bottomRight).distance;

    return (length1 + length2) / 2;
  }

  Future<void> _saveImage() async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Get the temporary directory path.
    final directory = await getTemporaryDirectory();
    final path = directory.path;

    // Create a file at the path.
    File imgFile = File('$path/screenshot.png');

    // Write the image bytes to the file.
    await imgFile.writeAsBytes(pngBytes);

    // Calculate the average box diagonal length in terms of the real-life diameter of the center circle
    final averageBoxDiagonalLength = calculateAverageBoxLength();
    final double realLifeDiameterCm =
        1.3; // The real-life diameter of the center circle is 1.3 cm
    final double diameterInPixels =
        35.0; // The diameter of the circle on the screen is 35 pixels
    final double scaleFactor = realLifeDiameterCm / diameterInPixels;
    final averageBoxDiagonalLengthInRealLife = averageBoxDiagonalLength *
        scaleFactor; // The average box diagonal length in cm
    final averageBoxDiagonalLengthInRealLifeInMM =
        averageBoxDiagonalLengthInRealLife * 10; // Convert from cm to mm

    print(
        "Average box diagonal length in MM: ${averageBoxDiagonalLengthInRealLifeInMM}");

    // Create a Completer that completes when the BottomSheet is closed
    Completer<void> bottomSheetCompleter = Completer();

    // Shows bottom sheet to ask user for reel type + show reel count result
    _showReelTypeForm(
        averageBoxDiagonalLengthInRealLifeInMM, bottomSheetCompleter);

    // Wait for the BottomSheet to be closed
    await bottomSheetCompleter.future;

    // Save the image to the gallery using gallery_saver
    GallerySaver.saveImage(imgFile.path, albumName: 'MyApp')
        .then((bool? success) {
      print("Saved the image as ${imgFile.path}");

      if (success!) {
        Navigator.of(context).pop(); // Go back to the camera view
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved successfully!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image.'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Picture'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: resetBoxCoordinates,
            tooltip: 'Reset Box',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveImage,
            tooltip: 'Save Image',
          ),
        ],
      ),
      body: GestureDetector(
        onPanDown: (details) {
          final touchPoint = details.localPosition;
          final double touchTolerance = 20.0;

          if ((topLeft - touchPoint).distance <= touchTolerance) {
            setState(() {
              topLeft = touchPoint;
              topRight = Offset(topRight.dx, touchPoint.dy);
              bottomLeft = Offset(touchPoint.dx, bottomLeft.dy);
            });
          } else if ((topRight - touchPoint).distance <= touchTolerance) {
            setState(() {
              topRight = touchPoint;
              topLeft = Offset(topLeft.dx, touchPoint.dy);
              bottomRight = Offset(touchPoint.dx, bottomRight.dy);
            });
          } else if ((bottomLeft - touchPoint).distance <= touchTolerance) {
            setState(() {
              bottomLeft = touchPoint;
              topLeft = Offset(touchPoint.dx, topLeft.dy);
              bottomRight = Offset(bottomRight.dx, touchPoint.dy);
            });
          } else if ((bottomRight - touchPoint).distance <= touchTolerance) {
            setState(() {
              bottomRight = touchPoint;
              topRight = Offset(touchPoint.dx, topRight.dy);
              bottomLeft = Offset(bottomLeft.dx, touchPoint.dy);
            });
          }
        },
        onPanUpdate: (details) {
          final touchPoint = details.localPosition;
          final double touchTolerance = 20.0;

          if ((topLeft - touchPoint).distance <= touchTolerance) {
            setState(() {
              topLeft = touchPoint;
              topRight = Offset(topRight.dx, touchPoint.dy);
              bottomLeft = Offset(touchPoint.dx, bottomLeft.dy);
            });
          } else if ((topRight - touchPoint).distance <= touchTolerance) {
            setState(() {
              topRight = touchPoint;
              topLeft = Offset(topLeft.dx, touchPoint.dy);
              bottomRight = Offset(touchPoint.dx, bottomRight.dy);
            });
          } else if ((bottomLeft - touchPoint).distance <= touchTolerance) {
            setState(() {
              bottomLeft = touchPoint;
              topLeft = Offset(touchPoint.dx, topLeft.dy);
              bottomRight = Offset(bottomRight.dx, touchPoint.dy);
            });
          } else if ((bottomRight - touchPoint).distance <= touchTolerance) {
            setState(() {
              bottomRight = touchPoint;
              topRight = Offset(touchPoint.dx, topRight.dy);
              bottomLeft = Offset(bottomLeft.dx, touchPoint.dy);
            });
          }
        },
        child: Stack(
          children: [
            RepaintBoundary(
              key: globalKey,
              child: Image.file(
                File(widget.imageFile.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            CustomPaint(
              painter: BoxPainter(
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoxPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  BoxPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    canvas.drawLine(topLeft, topRight, paint);
    canvas.drawLine(topRight, bottomRight, paint);
    canvas.drawLine(bottomRight, bottomLeft, paint);
    canvas.drawLine(bottomLeft, topLeft, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
