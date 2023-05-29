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
  List<List<Offset>> lines = [];
  Offset startPoint = Offset(0, 0);
  Offset endPoint = Offset(0, 0);
  int lineCount = 0;
  bool canDrawLines = true;

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

    // Calculate the average line length in terms of the real-life diameter of the center circle
    final averageLineLength = calculateAverageLineLength();
    const realLifeDiameter =
        1.3; // The real-life diameter of the center circle is 1.3 cm
    final scaleFactor = realLifeDiameter /
        MediaQuery.of(context)
            .size
            .width; // The scale factor to convert from pixels to cm
    final averageLineLengthInRealLife =
        averageLineLength * scaleFactor; // The average line length in cm
    final averageLineLengthInRealLifeInMM =
        averageLineLengthInRealLife * 10; // Convert from cm to mmFF

    // Create a Completer that completes when the BottomSheet is closed
    Completer<void> bottomSheetCompleter = Completer();

    // Shows bottom sheet to ask user for reel type + show reel count result
    _showReelTypeForm(averageLineLengthInRealLifeInMM, bottomSheetCompleter);

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

  void _showReelTypeForm(
      double averageLineLengthInMM, Completer<void> completer) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ReelTypeForm(averageLineLengthInMM, completer);
      },
    );
  }

  void updateLine(Offset newPoint) {
    final dx = newPoint.dx - startPoint.dx;
    final dy = newPoint.dy - startPoint.dy;
    final length = min(
        sqrt(dx * dx + dy * dy), 2000.0); // Maximum line length of 2000 pixels
    final angle = atan2(dy, dx);

    endPoint = Offset(
      startPoint.dx + length * cos(angle),
      startPoint.dy + length * sin(angle),
    );
  }

  void clearLines() {
    setState(() {
      lines.clear();
      lineCount = 0;
      startPoint = Offset.zero;
      endPoint = Offset.zero;
      canDrawLines = true;
    });
  }

  double calculateLienLength(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    return sqrt(dx * dx + dy * dy);
  }

  double calculateAverageLineLength() {
    if (lines.isEmpty) {
      return 0.0;
    }

    double totalLength = 0.0;
    for (var line in lines) {
      totalLength += calculateLienLength(line[0], line[1]);
    }

    return totalLength / lines.length;
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = AppBar().preferredSize.height;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double screenHeight =
        MediaQuery.of(context).size.height - appBarHeight - statusBarHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Picture'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '$lineCount/2',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: canDrawLines
                      ? Colors.white
                      : Colors
                          .red, // Update color based on line drawing availability
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearLines,
            tooltip: 'Clear Lines',
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
          RenderBox box = context.findRenderObject() as RenderBox;
          startPoint = box.globalToLocal(details.globalPosition) -
              Offset(0, appBarHeight + statusBarHeight);
          updateLine(startPoint);
        },
        onPanUpdate: (details) {
          RenderBox box = context.findRenderObject() as RenderBox;
          Offset newPoint = box.globalToLocal(details.globalPosition) -
              Offset(0, appBarHeight + statusBarHeight);
          updateLine(newPoint);
        },
        onPanEnd: (details) {
          if (canDrawLines) {
            lines.add([startPoint, endPoint]);
            setState(() {
              startPoint = Offset(0, 0);
              endPoint = Offset(0, 0);
              lineCount++;
            });

            if (lineCount >= 2) {
              setState(() {
                canDrawLines = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum of 2 lines allowed.'),
                ),
              );
            }
          }
        },
        child: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                key: globalKey,
                child: Stack(
                  children: [
                    Image.file(
                      File(widget.imageFile.path),
                      fit: BoxFit.cover,
                    ),
                    CustomPaint(
                      painter: LinePainter(
                          lines: lines,
                          startPoint: startPoint,
                          endPoint: endPoint),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final List<List<Offset>> lines;
  final Offset startPoint;
  final Offset endPoint;

  LinePainter(
      {required this.lines, required this.startPoint, required this.endPoint});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    for (var line in lines) {
      canvas.drawLine(line[0], line[1], paint);
    }

    if (startPoint != Offset(0, 0) && endPoint != Offset(0, 0)) {
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
