import 'dart:math';
import 'package:flutter/material.dart';

class ReelCounter extends StatefulWidget {
  @override
  _ReelCounterState createState() => _ReelCounterState();
}

class _ReelCounterState extends State<ReelCounter> {
  //New variables that need to be set by user
  //This value is in milimeters (mm)
  final TextEditingController widthOfRollController = TextEditingController();

  //Variables that should be fixed (selectable - based on reel type)
  //These values are in milimeteres (mm)
  double internalHubDiameter = 0.0;
  double tapeThickness = 0.0;
  double distanceBetweenComponents = 0.0;

  String _result = '';

  //Add dropdown items list to select reel type
  List<String> _reelType = ['0402', '0603'];
  String? selectedType;

  void updateValuesForSelectedReelType(String? type) {
    setState(() {
      if (type == '0402') {
        internalHubDiameter = 60.0;
        tapeThickness = 0.5;
        distanceBetweenComponents = 2.0;
      } else if (type == '0603') {
        internalHubDiameter = 60.0;
        tapeThickness = 0.5;
        distanceBetweenComponents = 4.0;
      }
    });
  }

  void _calculateReelEstimate() {
    if (widthOfRollController.text.isEmpty) {
      return;
    }

    //Use formula to calculate estimated reel count

    double r = double.parse(widthOfRollController.text);
    double h = internalHubDiameter;
    double m = tapeThickness;

    /*
    The outside diameter of the roll is the measured value of the hub,
    plus twice the measured value R. Note that the measurement of R measures 
    from the inside of the hub to the outside of the roll.
    D=H+2R
    */
    double d = h + 2 * m;

    /*
    The inside diameter of the roll is the external diameter of the hub.
    This is the measured internal diameter of the hub, plus twice the material thickness.
    d=H+2m
    */
    double bigD = h + 2 * r;
    /*
    First, the number of windings on the reel is calculated.
    Each winding adds the thickness of the tape over the entire circumference of the reel,
    and so the diameter increases by twice the thickness for each winding.
    From the difference between the outer diameter and the inner diameter of the roll, and the tape thickness,
    the number of windings is easily calculated.
    W=(D−d)/2T
    */
    double windings = (bigD - d) / (2 * tapeThickness);
    /*
    The roll of tape on the reel is a spiral.
    The length of the tape spiralled on the reel is the circumference of the average diameter,
    multiplied by the number of windings.
    L=D+d2⋅W⋅π
    */
    double length = (bigD + d) / 2 * windings * pi;
    /*
    Once the length of the tape is known, the number of components follows by dividing it by the pitch.
    */
    int estimatedComponents = (length / distanceBetweenComponents).round();

    setState(() {
      _result = "Estimated components on reel: $estimatedComponents";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reel Estimator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: widthOfRollController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Width of Roll (mm)'),
              ),
              DropdownButton<String>(
                hint: Text('Select Reel Type'),
                value: selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue;
                  });
                  updateValuesForSelectedReelType(newValue);
                },
                items: _reelType.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
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
          ),
        ),
      ),
    );
  }
}
