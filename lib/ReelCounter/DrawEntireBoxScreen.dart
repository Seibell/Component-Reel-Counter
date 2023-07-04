import 'dart:io';
import 'dart:async';
import 'package:component_reel_counter/ReelCounter/EditPictureScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class DrawEntireBoxScreen extends StatefulWidget {
  final XFile imageFile;

  DrawEntireBoxScreen({required this.imageFile});

  @override
  _DrawEntireBoxScreenState createState() => _DrawEntireBoxScreenState();
}

class _DrawEntireBoxScreenState extends State<DrawEntireBoxScreen> {
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

  double calculateAverageBoxLength() {
    final double length1 = (topLeft - topRight).distance;
    final double length2 = (topRight - bottomRight).distance;
    final double length3 = (bottomRight - bottomLeft).distance;
    final double length4 = (bottomLeft - topLeft).distance;

    print("******* Average Box length in DrawEntireBoxScreen is $length1");

    return (length1 + length2 + length3 + length4) / 4;
  }

  Future<void> _sendImageToSmallerBox() async {
    final averageBoxLength = calculateAverageBoxLength();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPictureScreen(
          imageFile: XFile(widget.imageFile.path),
          imageWidth: averageBoxLength,
          imageHeight: averageBoxLength,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Box entire reel'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: resetBoxCoordinates,
            tooltip: 'Reset Box',
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _sendImageToSmallerBox,
            tooltip: 'Next Step',
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
                fit: BoxFit.contain,
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
