import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import './DrawCircleAfterEditPictureScreen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditPictureScreen extends StatefulWidget {
  final XFile imageFile;
  final double imageHeight;
  final double imageWidth;

  EditPictureScreen(
      {required this.imageFile,
      required this.imageHeight,
      required this.imageWidth});

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

  double calculateAverageBoxLength() {
    final double length1 = (topLeft - topRight).distance;
    final double length2 = (topRight - bottomRight).distance;
    final double length3 = (bottomRight - bottomLeft).distance;
    final double length4 = (bottomLeft - topLeft).distance;

    print("******** Average Box length in EditPictureScreen is $length1");

    return (length1 + length2 + length3 + length4) / 4;
  }

  Future<void> _sendImageToDrawCircle() async {
    final averageBoxLength = calculateAverageBoxLength();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawCircleAfterEditPictureScreen(
          imageFile: XFile(widget.imageFile.path),
          imageWidth: widget.imageWidth,
          imageHeight: widget.imageHeight,
          averageBoxLength: averageBoxLength,
        ),
      ),
    );
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
            icon: const Icon(Icons.navigate_next),
            onPressed: _sendImageToDrawCircle,
            tooltip: 'Next Step (Draw Circle)',
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
