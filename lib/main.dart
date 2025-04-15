import 'package:flutter/material.dart';
import 'map_screen.dart';

void main() {
  runApp(FarmerApp());
}

class FarmerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farm Area Calculator',
      theme: ThemeData(primarySwatch: Colors.green),
      home: MapScreen(),
    );
  }
}
