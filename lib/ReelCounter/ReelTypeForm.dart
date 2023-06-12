import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

class ReelTypeForm extends StatefulWidget {
  final double averageLineLengthInMM;
  final Completer<void> completer;

  ReelTypeForm(this.averageLineLengthInMM, this.completer);

  @override
  _ReelTypeFormState createState() => _ReelTypeFormState();
}

class _ReelTypeFormState extends State<ReelTypeForm> {
  String? reelType;
  String? _result;

  final FocusNode _focusNode = FocusNode();

  //Variables that should be fixed (selectable - based on reel type)
  //These values are in milimeteres (mm)
  double internalHubDiameter = 0.0;
  double tapeThickness = 0.0;
  double distanceBetweenComponents = 0.0;

  void updateValuesForSelectedReelType(String? type) {
    setState(() {
      internalHubDiameter = 56.5;
      if (type == '0402') {
        tapeThickness = 0.85;
        distanceBetweenComponents = 2.0;
      } else if (type == '0603') {
        tapeThickness = 0.9;
        distanceBetweenComponents = 4.0;
      } else if (type == '0805') {
        tapeThickness = 0.95;
        distanceBetweenComponents = 4.0;
      } else if (type == '1206') {
        tapeThickness = 1.1;
        distanceBetweenComponents = 4.0;
      } else if (type == '1210') {
        tapeThickness = 1.25;
        distanceBetweenComponents = 4.0;
      } else if (type == '1218') {
        tapeThickness = 1.15;
        distanceBetweenComponents = 4.0;
      } else if (type == '2010') {
        tapeThickness = 1.2;
        distanceBetweenComponents = 4.0;
      } else if (type == '2512') {
        tapeThickness = 1.2;
        distanceBetweenComponents = 8.0;
      }
    });
  }

  void _calculateReelEstimate() {
    //Use formula to calculate estimated reel count

    double r = widget.averageLineLengthInMM;
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
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: reelType,
              items: <String>[
                '0402',
                '0603',
                '0805',
                '1206',
                '1210',
                '1218',
                '2010',
                '2510'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  reelType = newValue;
                  if (_result != null) {
                    _result =
                        null; // Reset the result if it's not the same as the current reelType
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Reel Type',
              ),
            ),
            ElevatedButton(
              child: Text(_result == null ? 'Submit' : 'OK'),
              onPressed: () {
                if (_result == null) {
                  updateValuesForSelectedReelType(reelType);
                  _calculateReelEstimate();
                } else {
                  setState(() {
                    _result =
                        null; // Reset the result after the 'OK' button is pressed
                  });
                  widget.completer.complete();
                }
              },
            ),
            if (_result != null)
              Container(
                margin: const EdgeInsets.all(10.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Text(_result!),
              ),
          ],
        ),
      ),
    );
  }
}
