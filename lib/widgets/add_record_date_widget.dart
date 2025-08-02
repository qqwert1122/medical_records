import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class AddRecordDateWidget extends StatefulWidget {
  const AddRecordDateWidget({super.key});

  @override
  State<AddRecordDateWidget> createState() => _AddRecordDateWidgetState();
}

class _AddRecordDateWidgetState extends State<AddRecordDateWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('날짜', style: AppTextStyle.subTitle),
        SizedBox(width: context.wp(4)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                LucideIcons.calendarDays,
                size: context.xl,
                color: AppColors.primary,
              ),
              SizedBox(width: context.wp(2)),
              Text('2025-08-01', style: AppTextStyle.body),
            ],
          ),
        ),
      ],
    );
  }
}
