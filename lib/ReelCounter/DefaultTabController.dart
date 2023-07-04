import 'package:flutter/material.dart';
import 'ReelCounter.dart';
import 'CameraView.dart';

class DefaultTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0, // Open ReelCounter by default
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calculate), text: "ReelCounter"),
              Tab(icon: Icon(Icons.camera), text: "Camera"),
            ],
          ),
          title: const Text('Reel Estimator'),
        ),
        body: TabBarView(
          children: [
            ReelCounter(),
            CameraView(),
          ],
        ),
      ),
    );
  }
}
