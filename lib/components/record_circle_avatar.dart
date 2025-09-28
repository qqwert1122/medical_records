import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordCircleAvatar extends StatelessWidget {
  final String name;
  final String color;
  final IconData? icon;
  final double size;

  const RecordCircleAvatar({
    super.key,
    required this.name,
    required this.color,
    this.icon,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color(int.parse(color));
    final isLightColor = _isLightColor(backgroundColor);
    final contentColor = isLightColor ? AppColors.textPrimary : AppColors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon != null
            ? Icon(
                icon,
                color: contentColor,
                size: size * 0.5,
              )
            : Text(
                name.isNotEmpty ? name[0].toUpperCase() : '',
                style: AppTextStyle.body.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
      ),
    );
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }
}