import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gallery_saver/gallery_saver.dart';
import './ReelTypeForm.dart';

class DrawCircleAfterEditPictureScreen extends StatefulWidget {
  final XFile imageFile;
  final double imageWidth;
  final double imageHeight;
  final double averageBoxLength;

  DrawCircleAfterEditPictureScreen(
      {required this.imageFile,
      required this.imageWidth,
      required this.imageHeight,
      required this.averageBoxLength});

  @override
  _DrawCircleScreenState createState() => _DrawCircleScreenState();
}

class _DrawCircleScreenState extends State<DrawCircleAfterEditPictureScreen> {
  GlobalKey globalKey = GlobalKey();
  Offset topLeft = Offset(0, 0);
  Offset topRight = Offset(0, 0);
  Offset bottomLeft = Offset(0, 0);
  Offset bottomRight = Offset(0, 0);
  double radius = 0;
  Offset center = Offset(0, 0);
  Offset previousTouchPoint = Offset.zero;
  bool isMovingCircle = false;

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
      radius = (initialLength + initialWidth) / 4;
    });
  }

  void resetBoxCoordinates() {
    setInitialBoxCoordinates();
  }

  void _showReelTypeForm(double averageBoxLength, double scaleFactor,
      double imageWidth, double imageHeight, Completer<void> completer) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ReelTypeForm(
            averageBoxLength, scaleFactor, imageWidth, imageHeight, completer);
      },
    );
  }

  double calculateRadius() {
    // Calculate the width and height of the bounding box
    double boxWidth = topRight.dx - topLeft.dx;
    double boxHeight = bottomLeft.dy - topLeft.dy;

    // The radius of the circle is half the average of the width and height
    return (boxWidth + boxHeight) / 4;
  }

  Future<void> _saveImage() async {
    // Calculations
    final double radius = calculateRadius();
    final double diameter = 2 * radius;
    // in real life - measured using a ruler
    const circleDiameterInRealLife = 59;

    final double scaleFactor = diameter / circleDiameterInRealLife;

    print("Diameter = $diameter");
    print("Scale Factor = $scaleFactor");

    // Create a Completer that completes when the BottomSheet is closed
    Completer<void> bottomSheetCompleter = Completer();

    // Shows bottom sheet to ask user for reel type + show reel count result
    _showReelTypeForm(widget.averageBoxLength, scaleFactor, widget.imageWidth,
        widget.imageHeight, bottomSheetCompleter);

    // Wait for the BottomSheet to be closed
    await bottomSheetCompleter.future;

    // Save the image to the gallery using gallery_saver
    GallerySaver.saveImage(widget.imageFile.path, albumName: 'MyApp')
        .then((bool? success) {
      print("Saved the image as ${widget.imageFile.path}");

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

          double distanceFromCenter = (center - touchPoint).distance;

          final double edgeTolerance = 30.0;

          if (distanceFromCenter <= radius) {
            // The touch is in the inner zone
            isMovingCircle = true;
            previousTouchPoint = touchPoint;
          } else if (distanceFromCenter <= radius + edgeTolerance) {
            // The touch is in the edge zone
            isMovingCircle = false;
            previousTouchPoint = touchPoint;
          }
        },
        onPanUpdate: (details) {
          final touchPoint = details.localPosition;

          if (previousTouchPoint != Offset.zero) {
            // Check if we have a valid previous touch point
            if (isMovingCircle) {
              setState(() {
                final delta = touchPoint - previousTouchPoint;
                center = Offset(
                  center.dx + delta.dx,
                  center.dy + delta.dy,
                );
                topLeft += delta;
                topRight += delta;
                bottomLeft += delta;
                bottomRight += delta;
                previousTouchPoint = touchPoint;

                // Recalculate the radius after moving the circle
                radius = calculateRadius();
              });
            } else {
              setState(() {
                radius = (center - touchPoint).distance;
                topLeft = center - Offset(radius, radius);
                topRight = center + Offset(radius, -radius);
                bottomLeft = center - Offset(radius, -radius);
                bottomRight = center + Offset(radius, radius);

                // Recalculate the center and the radius after resizing the circle
                center = Offset(
                  (topLeft.dx + topRight.dx + bottomLeft.dx + bottomRight.dx) /
                      4,
                  (topLeft.dy + topRight.dy + bottomLeft.dy + bottomRight.dy) /
                      4,
                );
                radius = calculateRadius();
              });
            }
          }
        },
        onPanEnd: (details) {
          setState(() {
            isMovingCircle = false;
            previousTouchPoint = Offset.zero;
          });
        },
        child: Stack(
          children: [
            RepaintBoundary(
              key: globalKey,
              child: Image.file(
                File(widget.imageFile.path),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            CustomPaint(
              painter: CirclePainter(
                center: center = Offset(
                  (topLeft.dx + topRight.dx + bottomLeft.dx + bottomRight.dx) /
                      4,
                  (topLeft.dy + topRight.dy + bottomLeft.dy + bottomRight.dy) /
                      4,
                ),
                radius: radius = calculateRadius(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final Offset center;
  final double radius;

  CirclePainter({
    required this.center,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
