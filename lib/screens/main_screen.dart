import 'package:flutter/material.dart';
import 'package:medical_records/screens/photo_page.dart';
import 'package:medical_records/screens/record_page.dart';
import 'package:medical_records/services/app_colors.dart';
import 'package:medical_records/services/app_size.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [RecordPage(), PhotoPage()];

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '기록'),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: '사진'),
        ],
      ),
    );
  }
}
