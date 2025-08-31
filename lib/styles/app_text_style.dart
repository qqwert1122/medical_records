import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';

class AppTextStyle {
  static TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );
  static TextStyle subTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );
  static TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
  );
  static TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: -0.8,
  );
  static TextStyle hint = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.lightGrey,
    letterSpacing: -0.8,
  );
}
