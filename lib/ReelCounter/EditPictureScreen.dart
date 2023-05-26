import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver/gallery_saver.dart';

class EditPictureScreen extends StatefulWidget {
  final XFile imageFile;

  EditPictureScreen({required this.imageFile});

  @override
  _EditPictureScreenState createState() => _EditPictureScreenState();
}

class _EditPictureScreenState extends State<EditPictureScreen> {
  GlobalKey globalKey = GlobalKey();
  List<List<Offset>> lines = [];

  void _updateLineEndpoints(Offset startPoint, Offset endPoint) {
    setState(() {
      if (lines.isEmpty) {
        lines.add([startPoint, endPoint]);
      } else if (lines.length == 1) {
        lines[0] = [startPoint, endPoint];
      } else {
        lines.clear();
        lines.add([startPoint, endPoint]);
      }
    });
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
    double appBarHeight = AppBar().preferredSize.height;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double screenHeight =
        MediaQuery.of(context).size.height - appBarHeight - statusBarHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Picture'),
        actions: <Widget>[
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
          Offset startPoint = box.globalToLocal(details.globalPosition);
          Offset endPoint = box.globalToLocal(details.globalPosition);
          _updateLineEndpoints(
              Offset(startPoint.dx, startPoint.dy - appBarHeight),
              Offset(endPoint.dx, endPoint.dy - appBarHeight));
        },
        onPanUpdate: (details) {
          RenderBox box = context.findRenderObject() as RenderBox;
          Offset endPoint = box.globalToLocal(details.globalPosition);
          _updateLineEndpoints(
              lines[0][0], Offset(endPoint.dx, endPoint.dy - appBarHeight));
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
                      painter: LinePainter(lines: lines),
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

  LinePainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    for (var line in lines) {
      canvas.drawLine(line[0], line[1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
