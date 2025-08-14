import 'package:flutter/material.dart';

class AppColors {
  static Color primary = Colors.black;
  static Color accent = const Color(0xFFE53E3E);
  static Color get primaryLight => primary.withValues(alpha: 0.3);

  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF7F7F7);

  static const Color black = Color(0xFF333333);
  static const Color grey = Color(0xFFBBBBBB);
  static const Color white = Colors.white;

  static const Color textPrimary = Colors.black;

  static void changeTheme(Color newPrimary, Color newAccent) {
    primary = newPrimary;
    accent = newAccent;
  }

  static Color getTextColor(Color backgroundColor) {
    // 배경색의 밝기 계산 (0.0 ~ 1.0)
    double luminance = backgroundColor.computeLuminance();

    // 밝기가 0.5보다 크면 어두운 텍스트(검정), 작으면 밝은 텍스트(흰색)
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
