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

  static double get fontXS => 10.0;
  static double get fontSM => 12.0;
  static double get fontMD => 14.0;
  static double get fontLG => 16.0;
  static double get fontXL => 18.0;
  static double get fontXXL => 20.0;

  static double get paddingXS => 4.0;
  static double get paddingSM => 8.0;
  static double get paddingMD => 12.0;
  static double get paddingLG => 16.0;
  static double get paddingXL => 20.0;
  static double get paddingXXL => 24.0;

  static double get paddingHorizXS => 6.0;
  static double get paddingHorizSM => 12.0;
  static double get paddingHorizMD => 18.0;
  static double get paddingHorizLG => 24.0;
  static double get paddingHorizXL => 30.0;
  static double get paddingHorizXXL => 36.0;
}
