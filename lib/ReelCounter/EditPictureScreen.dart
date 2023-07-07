import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './DrawCircleAfterEditPictureScreen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:math';

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
  Offset boxCenter = const Offset(0, 0);
  Offset previousTouchPoint = const Offset(0, 0);
  Offset topLeft = const Offset(0, 0);
  Offset topRight = const Offset(0, 0);
  Offset bottomLeft = const Offset(0, 0);
  Offset bottomRight = const Offset(0, 0);

  bool isMoving = false;

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

  Offset calculateBoxCenter() {
    final double centerX =
        (topLeft.dx + topRight.dx + bottomLeft.dx + bottomRight.dx) / 4;
    final double centerY =
        (topLeft.dy + topRight.dy + bottomLeft.dy + bottomRight.dy) / 4;

    return Offset(centerX, centerY);
  }

  void translateBox(Offset translation) {
    setState(() {
      topLeft += translation;
      topRight += translation;
      bottomLeft += translation;
      bottomRight += translation;
    });
  }

  void adjustRectangleToSquare() {
    final double width = topRight.dx - topLeft.dx;
    final double height = bottomLeft.dy - topLeft.dy;

    if (width != height) {
      final double minLength = width < height ? width : height;

      setState(() {
        topRight = Offset(topLeft.dx + minLength, topLeft.dy);
        bottomLeft = Offset(topLeft.dx, topLeft.dy + minLength);
        bottomRight = Offset(topRight.dx, bottomLeft.dy);
      });
    }
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
        title: Text('Box remaining reel'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: resetBoxCoordinates,
            tooltip: 'Reset Box',
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: _sendImageToDrawCircle,
            tooltip: 'Next Step',
          ),
        ],
      ),
      body: GestureDetector(
        onPanDown: (details) {
          final touchPoint = details.localPosition;
          const double touchTolerance = 40.0;
          boxCenter = calculateBoxCenter();

          if ((boxCenter - touchPoint).distance <= touchTolerance) {
            isMoving = true;
          } else {
            if ((bottomRight - touchPoint).distance <= touchTolerance) {
              isMoving = false;
            }
          }
          previousTouchPoint = touchPoint;
        },
        onPanUpdate: (details) {
          final touchPoint = details.localPosition;
          const double touchTolerance = 60.0;

          if (isMoving) {
            final translation = touchPoint - previousTouchPoint;

            // Prevent the box from moving out of screen bounds
            final screenSize = MediaQuery.of(context).size;
            if (topLeft.dx + translation.dx >= 0 &&
                topRight.dx + translation.dx <= screenSize.width &&
                topLeft.dy + translation.dy >= 0 &&
                bottomLeft.dy + translation.dy <= screenSize.height) {
              translateBox(translation);
            }
          } else {
            Offset? newCorner;
            Offset? oppositeCorner;
            if ((topLeft - previousTouchPoint).distance <= touchTolerance) {
              newCorner = Offset(touchPoint.dx.clamp(0, bottomRight.dx),
                  touchPoint.dy.clamp(0, bottomRight.dy));
              oppositeCorner = bottomRight;
            } else if ((topRight - previousTouchPoint).distance <=
                touchTolerance) {
              newCorner = Offset(
                  touchPoint.dx
                      .clamp(topLeft.dx, MediaQuery.of(context).size.width),
                  touchPoint.dy.clamp(0, bottomLeft.dy));
              oppositeCorner = bottomLeft;
            } else if ((bottomLeft - previousTouchPoint).distance <=
                touchTolerance) {
              newCorner = Offset(
                  touchPoint.dx.clamp(0, topRight.dx),
                  touchPoint.dy
                      .clamp(topRight.dy, MediaQuery.of(context).size.height));
              oppositeCorner = topRight;
            } else if ((bottomRight - previousTouchPoint).distance <=
                touchTolerance) {
              newCorner = Offset(
                  touchPoint.dx
                      .clamp(bottomLeft.dx, MediaQuery.of(context).size.width),
                  touchPoint.dy
                      .clamp(topLeft.dy, MediaQuery.of(context).size.height));
              oppositeCorner = topLeft;
            }

            final newLength = min((newCorner!.dx - oppositeCorner!.dx).abs(),
                (newCorner.dy - oppositeCorner.dy).abs());

            setState(() {
              if ((topLeft - previousTouchPoint).distance <= touchTolerance) {
                topLeft = Offset(oppositeCorner!.dx - newLength,
                    oppositeCorner.dy - newLength);
                topRight = Offset(oppositeCorner.dx, topLeft.dy);
                bottomLeft = Offset(topLeft.dx, oppositeCorner.dy);
                bottomRight = oppositeCorner;
              } else if ((topRight - previousTouchPoint).distance <=
                  touchTolerance) {
                topRight = Offset(oppositeCorner!.dx + newLength,
                    oppositeCorner.dy - newLength);
                topLeft = Offset(oppositeCorner.dx, topRight.dy);
                bottomRight = Offset(topRight.dx, oppositeCorner.dy);
                bottomLeft = oppositeCorner;
              } else if ((bottomLeft - previousTouchPoint).distance <=
                  touchTolerance) {
                bottomLeft = Offset(oppositeCorner!.dx - newLength,
                    oppositeCorner.dy + newLength);
                topLeft = Offset(bottomLeft.dx, oppositeCorner.dy);
                bottomRight = Offset(oppositeCorner.dx, bottomLeft.dy);
                topRight = oppositeCorner;
              } else if ((bottomRight - previousTouchPoint).distance <=
                  touchTolerance) {
                bottomRight = Offset(oppositeCorner!.dx + newLength,
                    oppositeCorner.dy + newLength);
                topRight = Offset(bottomRight.dx, oppositeCorner.dy);
                bottomLeft = Offset(oppositeCorner.dx, bottomRight.dy);
                topLeft = oppositeCorner;
              }
            });
          }
          previousTouchPoint = touchPoint;
        },
        onPanEnd: (details) {
          isMoving = false;
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
