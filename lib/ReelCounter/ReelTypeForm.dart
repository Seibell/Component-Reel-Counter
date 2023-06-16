import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

class ReelTypeForm extends StatefulWidget {
  final double averageLineLength;
  final double scaleFactor;
  final double imageWidth;
  final double imageHeight;
  final Completer<void> completer;

  ReelTypeForm(this.averageLineLength, this.scaleFactor, this.imageWidth,
      this.imageHeight, this.completer);

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
  int componentsOnReel = 0;

  void updateNumberOfComponentsOnReel(String? num) {
    setState(() {
      internalHubDiameter = 56.5;
      if (num == '500') {
        componentsOnReel = 500;
      } else if (num == '1000') {
        componentsOnReel = 1000;
      } else if (num == '2000') {
        componentsOnReel = 2000;
      } else if (num == '3000') {
        componentsOnReel = 3000;
      } else if (num == '4000') {
        componentsOnReel = 4000;
      } else if (num == '5000') {
        componentsOnReel = 5000;
      } else if (num == '6000') {
        componentsOnReel = 6000;
      } else if (num == '10000') {
        componentsOnReel = 10000;
      }
    });
  }

  void _calculateReelEstimate() {
    //Use proportion to estimate reel count

    //Calculate the length of the box in real life (mm) which is the estimated reel width
    double lineLengthInMM = widget.averageLineLength / widget.scaleFactor;
    double entireReelWidthInMM = widget.imageWidth / widget.scaleFactor;
    double entireReelHeightInMM = widget.imageHeight / widget.scaleFactor;

    print("Line Length: ${widget.averageLineLength}");
    print("Entire Reel Width: ${widget.imageWidth}");
    print("Entire Reel Height: ${widget.imageHeight}");

    print("Line Length in MM: $lineLengthInMM");
    print("Entire Reel Width in MM: $entireReelWidthInMM");
    print("Entire Reel Height in MM: $entireReelHeightInMM");

    // Find area of component reel
    double componentReelArea = pi * (lineLengthInMM / 2) * (lineLengthInMM / 2);

    // Find area of inner reel (to be subtracted from component reel)
    double innerReelArea =
        pi * (internalHubDiameter / 2) * (internalHubDiameter / 2);

    // Find area of entire reel (100%)
    double averageEntireReelHeightWidth =
        (entireReelHeightInMM + entireReelWidthInMM) / 2;
    double entireComponentReelArea = pi *
        (averageEntireReelHeightWidth / 2) *
        (averageEntireReelHeightWidth / 2);

    componentReelArea = componentReelArea - innerReelArea;
    entireComponentReelArea = entireComponentReelArea - innerReelArea;

    // Find percentage of component reel area to entire reel area
    double percentageOfComponentReelArea =
        componentReelArea / entireComponentReelArea;

    // User input
    int numberOfComponentsOnReel = componentsOnReel;

    // Find the number of components on the reel
    double numberOfComponentsOnReelEstimate =
        numberOfComponentsOnReel * percentageOfComponentReelArea;

    // Print all variables
    print("Component Reel Area: $componentReelArea");
    print("Inner Reel Area: $innerReelArea");
    print("Entire Component Reel Area: $entireComponentReelArea");
    print("Percentage of Component Reel Area: $percentageOfComponentReelArea");
    print(
        "Number of Components on Reel Estimate: $numberOfComponentsOnReelEstimate");

    setState(() {
      _result =
          "Estimated components on reel: $numberOfComponentsOnReelEstimate";
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
                '500',
                '1000',
                '2000',
                '3000',
                '4000',
                '5000',
                '6000',
                '10000'
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
                  updateNumberOfComponentsOnReel(reelType);
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
