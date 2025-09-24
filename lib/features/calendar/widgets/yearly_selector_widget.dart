import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class YearlySelectorWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final VoidCallback onDateTap;

  const YearlySelectorWidget({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              onDateChanged(
                DateTime(selectedDate.year - 1, selectedDate.month),
              );
            },
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onDateTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${selectedDate.year}년',
                style: AppTextStyle.subTitle,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              onDateChanged(
                DateTime(selectedDate.year + 1, selectedDate.month),
              );
            },
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }
}
