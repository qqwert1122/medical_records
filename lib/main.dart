import 'package:flutter/material.dart';
import 'package:medical_records/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Medical Records', home: MainScreen());
  }
}
