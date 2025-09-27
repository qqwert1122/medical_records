import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';

class ProgressSection extends StatelessWidget {
  final int activeRecords;

  const ProgressSection({super.key, required this.activeRecords});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          // color: AppColors.surface,
          color: Colors.indigoAccent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 10.0,
              children: [
                Icon(
                  LucideIcons.circleDashed,
                  size: 24,
                  color: AppColors.white,
                ),
                Text(
                  '진행 중',
                  style: AppTextStyle.body.copyWith(color: AppColors.white),
                ),
              ],
            ),
            Text(
              activeRecords.toString(),
              style: AppTextStyle.subTitle.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
