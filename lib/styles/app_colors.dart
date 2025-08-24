import 'package:flutter/material.dart';

class AppColors {
  static bool get isDarkMode =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  static Color primary = Colors.pinkAccent;
  static Color get primaryLight => primary.withValues(alpha: 0.3);

  static Color get background =>
      isDarkMode ? const Color(0xFF333333) : Colors.white;
  static Color get backgroundSecondary =>
      isDarkMode ? const Color(0xFF3C3C3C) : Color(0xFFEBEBEB);
  static Color get surface =>
      isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF7F7F7);

  static Color get textPrimary => isDarkMode ? white : Color(0xFF333333);
  static Color get textSecondary => isDarkMode ? white : Color(0xFFBBBBBB);

  static Color get shadow => isDarkMode ? Color(0xFFBBBBBB) : Color(0xFF333333);

  static const Color black = Color(0xFF333333);
  static const Color darkGrey = Color(0xFF31363F);
  static const Color lightGrey = Color(0xFFBBBBBB);
  static const Color white = Colors.white;

  static void changeTheme(Color newPrimary) {
    primary = newPrimary;
  }

  // 배경색에 따라 적절한 폰트 색깔 return
  static Color getTextColor(Color backgroundColor) {
    // 배경색의 밝기 계산 (0.0 ~ 1.0)
    double luminance = backgroundColor.computeLuminance();

    // 밝기가 0.5보다 크면 어두운 텍스트(검정), 작으면 밝은 텍스트(흰색)
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
