import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class MonthSelectorWidget extends StatelessWidget {
  final DateTime focusedDay;
  final Function(DateTime) onMonthChanged;
  final VoidCallback onMonthTap;

  const MonthSelectorWidget({
    Key? key,
    required this.focusedDay,
    required this.onMonthChanged,
    required this.onMonthTap,
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
              onMonthChanged(DateTime(focusedDay.year, focusedDay.month - 1));
            },
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onMonthTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${focusedDay.year}년 ${focusedDay.month}월',
                style: AppTextStyle.subTitle,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              onMonthChanged(DateTime(focusedDay.year, focusedDay.month + 1));
            },
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }
}
