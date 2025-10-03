import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';

class AppTextStyle {
  static TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800, // ExtraBold
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );
  static TextStyle subTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );
  static TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );
  static TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.textSecondary,
    letterSpacing: -0.8,
  );
  static TextStyle hint = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w300, // Light
    color: AppColors.lightGrey,
    letterSpacing: -0.8,
  );
}
