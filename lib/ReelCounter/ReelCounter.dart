import 'dart:math';
import 'package:flutter/material.dart';

class ReelCounter extends StatefulWidget {
  @override
  _ReelCounterState createState() => _ReelCounterState();
}

class _ReelCounterState extends State<ReelCounter> {
  final TextEditingController _diameterController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _componentController = TextEditingController();
  String _result = '';

  void _calculateReelEstimate() {
    if (_diameterController.text.isEmpty ||
        _widthController.text.isEmpty ||
        _componentController.text.isEmpty) {
      return;
    }

    double reelDiameter = double.parse(_diameterController.text);
    double tapeWidth = double.parse(_widthController.text);
    double componentHeight = double.parse(_componentController.text);

    double tapeLength =
        pi * (reelDiameter - tapeWidth) * reelDiameter / tapeWidth;
    double componentsPerMeter = 1000.0 / (2.0 * componentHeight);

    int estimatedComponents = (tapeLength * componentsPerMeter).round();

    setState(() {
      _result = 'Estimated components on reel: $estimatedComponents';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Reel Estimator',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: _diameterController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Reel Diameter (mm)'),
        ),
        TextField(
          controller: _widthController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Tape Width (mm)'),
        ),
        TextField(
          controller: _componentController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Component Height (mm)'),
        ),
        ElevatedButton(
          onPressed: _calculateReelEstimate,
          child: Text('Calculate Reel Estimate'),
        ),
        SizedBox(height: 20),
        Text(
          _result,
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
