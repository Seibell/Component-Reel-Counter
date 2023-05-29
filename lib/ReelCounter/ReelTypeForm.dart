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
  String? result;

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
              items: <String>['0402', '0603'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  reelType = newValue;
                  if (result != null &&
                      result !=
                          'The average length of the lines for reel type $reelType is approximately ${widget.averageLineLengthInMM.toStringAsFixed(2)} mm.') {
                    result =
                        null; // Reset the result if it's not the same as the current reelType
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Reel Type',
              ),
            ),
            ElevatedButton(
              child: Text(result == null ? 'Submit' : 'OK'),
              onPressed: () {
                if (result == null) {
                  setState(() {
                    result =
                        'The average length of the lines for reel type $reelType is approximately ${widget.averageLineLengthInMM.toStringAsFixed(2)} mm.';
                  });
                } else {
                  setState(() {
                    result =
                        null; // Reset the result after the 'OK' button is pressed
                  });
                  widget.completer.complete();
                }
              },
            ),
            if (result != null)
              Container(
                margin: const EdgeInsets.all(10.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Text(result!),
              ),
          ],
        ),
      ),
    );
  }
}
