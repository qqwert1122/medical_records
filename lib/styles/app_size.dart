import 'package:flutter/material.dart';

class AppSize {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
  }

  static double hp(double percentage) {
    return (percentage / 100) * screenHeight;
  }

  static double wp(double percentage) {
    return (percentage / 100) * screenWidth;
  }

  static double get xs => 4.0;
  static double get sm => 8.0;
  static double get md => 12.0;
  static double get lg => 16.0;
  static double get xl => 20.0;
  static double get xxl => 24.0;
}
