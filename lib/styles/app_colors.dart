import 'package:flutter/material.dart';

class AppColors {
  static Color primary = Colors.black;
  static Color accent = const Color(0xFFE53E3E);
  static Color get primaryLight => primary.withValues(alpha: 0.3);

  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF7F7F7);

  static const Color black = Colors.black;
  static const Color grey = Color(0xFFBBBBBB);
  static const Color white = Colors.white;

  static void changeTheme(Color newPrimary, Color newAccent) {
    primary = newPrimary;
    accent = newAccent;
  }
}
