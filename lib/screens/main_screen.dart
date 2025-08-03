import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  int _currentIndex = 0;

  final List<Widget> _pages = [Records(), PhotoPage(), SettingPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.squareGantt),
            label: '내 기록',
          ),
          BottomNavigationBarItem(icon: Icon(LucideIcons.image), label: '사진'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
