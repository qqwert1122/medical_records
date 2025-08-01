import 'package:flutter/material.dart';

class AppColors {
  static Color primary = Colors.black;
  static Color accent = const Color(0xFFE53E3E);

  static const Color secondary = Color(0xFFFFB6C1);
  static const Color background = Color(0xFFF7F7F7);
  static const Color surface = Colors.white;

  static const Color black = Colors.black;
  static const Color darkGrey = Color(0xFF424242);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color white = Colors.white;
  static Color get primaryLight => primary.withValues(alpha: 0.3);

  static void changeTheme(Color newPrimary, Color newAccent) {
    primary = newPrimary;
    accent = newAccent;
  }
}
