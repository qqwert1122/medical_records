import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/calendar/screens/calendar_page.dart';
import 'package:medical_records/screens/records.dart';
import 'package:medical_records/screens/photo_page.dart';
import 'package:medical_records/screens/record_foam_page.dart';
import 'package:medical_records/screens/setting_page.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: CalendarPage());
  }
}
