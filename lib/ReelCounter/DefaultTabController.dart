import 'package:flutter/material.dart';
import 'ReelCounter.dart';
import 'CameraView.dart';
import 'SelectTypeReelForm.dart';

class DefaultTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0, // Open ReelCounter by default
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calculate), text: "Reel Calc"),
              Tab(icon: Icon(Icons.camera), text: "Camera"),
              Tab(icon: Icon(Icons.account_box_sharp), text: "Select Size")
            ],
          ),
          title: const Text('Reel Estimator'),
        ),
        body: TabBarView(
          children: [
            ReelCounter(),
            CameraView(),
            SelectReelTypeForm(),
          ],
        ),
      ),
    );
  }
}
