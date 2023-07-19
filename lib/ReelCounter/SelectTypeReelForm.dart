import 'dart:math';
import 'package:flutter/material.dart';

class SelectReelTypeForm extends StatefulWidget {
  @override
  _SelectReelTypeFormState createState() => _SelectReelTypeFormState();
}

class _SelectReelTypeFormState extends State<SelectReelTypeForm> {
  //New variables that need to be set by user
  //This value is in milimeters (mm)
  final TextEditingController widthOfRollController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  //Variables that should be fixed (selectable - based on reel type)
  //These values are in milimeteres (mm)
  double internalHubDiameter = 0.0;
  double tapeThickness = 0.0;
  double distanceBetweenComponents = 0.0;

  String _result = '';

  // Dispose
  @override
  void dispose() {
    widthOfRollController.clear();
    _focusNode.dispose();
    selectedDimension = null;
    selectedType = null;
    _result = '';
    super.dispose();
  }

  //Add dropdown items list to select reel type
  final List<String> _reelType = ['Capacitor', 'Resistor', 'IC', 'Diode'];
  String? selectedType;

  //Add dropdown items list to select reel dimension
  List<String> _reelDimensions = [];
  String? selectedDimension;

  void setReelDimensions() {
    if (selectedType == 'IC') {
      _reelDimensions = [
        'SOT23',
        'SOT323',
        'SOT89',
        'SOT223',
        'SOT25',
        'SOT143',
        'SOT223-5',
        'SOT353'
      ];
    } else if (selectedType == "Diode") {
      _reelDimensions = [
        'SOT123',
        'SOT323',
        'MELF',
      ];
    } else {
      _reelDimensions = [
        '0402',
        '0603',
        '0805',
        '1206',
        '1210',
        '1812',
        '2010',
        '2512'
      ];
    }
  }

  // Typical reel sizes and esimates on dimensions based on EIA481 standard (http://www.lintronics.cn/upload/file/1377676284.PDF)
  void updateValuesForSelectedReelType(String? type) {
    setState(() {
      // Internal hub diameter for 7 inch reels should be standard
      internalHubDiameter = 59;

      switch (type) {
        case 'Capacitor':
        case 'Resistor':
          switch (selectedDimension) {
            case '0402':
              tapeThickness = 0.65;
              distanceBetweenComponents = 4.0;
              break;
            case '0603':
              tapeThickness = 0.75;
              distanceBetweenComponents = 4.0;
              break;
            case '0805':
              tapeThickness = 0.85;
              distanceBetweenComponents = 4.0;
              break;
            case '1206':
              tapeThickness = 0.85;
              distanceBetweenComponents = 4.0;
              break;
            case '1210':
              tapeThickness = 1.55;
              distanceBetweenComponents = 8.0;
              break;
            case '1812':
              tapeThickness = 1.57;
              distanceBetweenComponents = 12.0;
              break;
            case '2010':
              tapeThickness = 1.57;
              distanceBetweenComponents = 12.0;
              break;
            case '2512':
              tapeThickness = 1.57;
              distanceBetweenComponents = 16.0;
              break;
          }
          break;
        case 'IC':
          switch (selectedDimension) {
            case 'SOT23':
              tapeThickness = 0.3 + 0.2 + 1;
              distanceBetweenComponents = 4.0;
              break;
            case 'SOT323':
              tapeThickness = 0.3 + 0.2 + 1;
              distanceBetweenComponents = 2.0;
              break;
            case 'SOT89':
              tapeThickness = 0.3 + 0.2 + 1.5;
              distanceBetweenComponents = 12.0;
              break;
            case 'SOT223':
              tapeThickness = 0.3 + 0.2 + 1.8;
              distanceBetweenComponents = 12.7;
              break;
            case 'SOT25':
              tapeThickness = 0.3 + 0.2 + 1;
              distanceBetweenComponents = 4.0;
              break;
            case 'SOT143':
              tapeThickness = 0.3 + 0.2 + 1.3;
              distanceBetweenComponents = 8.0;
              break;
            case 'SOT223-5':
              tapeThickness = 0.3 + 0.2 + 1.8;
              distanceBetweenComponents = 12.7;
              break;
            case 'SOT353':
              tapeThickness = 0.3 + 0.2 + 1;
              distanceBetweenComponents = 4.0;
              break;
          }
          break;
        case 'Diode':
          switch (selectedDimension) {
            case 'SOD123':
              tapeThickness = 0.3 + 0.2 + 1.1;
              distanceBetweenComponents = 4.0;
              break;
            case 'SOD323':
              tapeThickness = 0.3 + 0.2 + 1;
              distanceBetweenComponents = 2.0;
              break;
            case 'MELF':
              tapeThickness = 0.3 + 0.2 + 1.4;
              distanceBetweenComponents = 8.0;
              break;
          }
          break;
      }
    });
  }

  void _calculateReelEstimate() {
    if (widthOfRollController.text.isEmpty) {
      return;
    }

    //Use formula to calculate estimated reel count
    double R = double.parse(widthOfRollController.text);
    double H = internalHubDiameter;
    double T = tapeThickness;
    double m = 0.0; // Assume 0 for simplicity
    double pitch = distanceBetweenComponents;

    /*
    The outside diameter of the roll is the measured value of the hub,
    plus twice the measured value R. Note that the measurement of R measures 
    from the inside of the hub to the outside of the roll.
    D=H+2R
    */
    double D = H + 2 * R;

    /*
    The inside diameter of the roll is the external diameter of the hub.
    This is the measured internal diameter of the hub, plus twice the material thickness.
    d=H+2m
    */
    double d = H + 2 * m;
    /*
    First, the number of windings on the reel is calculated.
    Each winding adds the thickness of the tape over the entire circumference of the reel,
    and so the diameter increases by twice the thickness for each winding.
    From the difference between the outer diameter and the inner diameter of the roll, and the tape thickness,
    the number of windings is easily calculated.
    W=(D−d)/2T
    */
    double windings = (D - d) / (2 * T);
    /*
    The roll of tape on the reel is a spiral.
    The length of the tape spiralled on the reel is the circumference of the average diameter,
    multiplied by the number of windings.
    L=D+d2⋅W⋅π
    */
    double length = (D + d) / 2 * windings * pi;
    /*
    Once the length of the tape is known, the number of components follows by dividing it by the pitch.
    */
    int estimatedComponents = (length / pitch).round();

    setState(() {
      _result = "Estimated components on reel: $estimatedComponents";
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus(); // dismiss keyboard
          }
        },
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: widthOfRollController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Width of Roll (mm)'),
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    hint: const Text('Select Reel Type'),
                    value: selectedType,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedType = newValue;
                      });
                      setReelDimensions();
                    },
                    items:
                        _reelType.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    hint: const Text('Select Reel Dimension'),
                    value: selectedDimension,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDimension = newValue;
                      });
                      updateValuesForSelectedReelType(selectedType);
                    },
                    items: _reelDimensions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _calculateReelEstimate,
                    child: const Text('Calculate Reel Estimate'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _result,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
