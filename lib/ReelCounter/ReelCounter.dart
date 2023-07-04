import 'dart:math';
import 'package:flutter/material.dart';

class ReelCounter extends StatefulWidget {
  @override
  _ReelCounterState createState() => _ReelCounterState();
}

class _ReelCounterState extends State<ReelCounter> {
  // Values are in milimeters (mm)
  final TextEditingController widthOfRollController = TextEditingController();
  final TextEditingController internalHubDiameterController =
      TextEditingController();
  final TextEditingController hubMaterialThickness = TextEditingController();
  final TextEditingController tapeThicknessController = TextEditingController();
  final TextEditingController componentPitchController =
      TextEditingController();

  final FocusNode _focusNode = FocusNode();

  String _result = '';

  void _calculateReelEstimate() {
    if (widthOfRollController.text.isEmpty) {
      return;
    }

    //Use formula to calculate estimated reel count

    double R = double.parse(widthOfRollController.text);
    double H = double.parse(internalHubDiameterController.text);
    double m = double.parse(hubMaterialThickness.text);
    double T = double.parse(tapeThicknessController.text);
    double pitch = double.parse(componentPitchController.text);

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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: widthOfRollController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Width of Roll, R (mm)'),
                    ),
                    TextField(
                      controller: internalHubDiameterController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Internal Hub Diameter, H (mm)'),
                    ),
                    TextField(
                      controller: hubMaterialThickness,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Hub Material Thickness, m (mm)'),
                    ),
                    TextField(
                      controller: tapeThicknessController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Tape Thickness, T (mm)'),
                    ),
                    TextField(
                      controller: componentPitchController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Distance Between Components, Pitch (mm)'),
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
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Image.asset('images/Reference_Reel.png'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
