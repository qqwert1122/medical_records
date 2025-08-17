import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/records/screens/setting_page.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarHeaderWidget extends StatelessWidget {
  final bool isMonthlyView;
  final Function(bool) onToggle;
  final DateTime focusedDay;
  final Function() onDateTap;

  const CalendarHeaderWidget({
    Key? key,
    required this.isMonthlyView,
    required this.onToggle,
    required this.focusedDay,
    required this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(2),
      ),
      child: Row(
        spacing: 10,
        children: [
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 4,
                children: [
                  Text(
                    isMonthlyView
                        ? '${focusedDay.year}년 ${focusedDay.month}월'
                        : '${focusedDay.year}년',
                    style: AppTextStyle.subTitle,
                  ),
                  Icon(LucideIcons.chevronDown, size: context.xl),
                ],
              ),
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: EdgeInsets.all(context.wp(2.5)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.image,
                color: AppColors.black,
                size: context.wp(5),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingPage()),
              );
            },
            child: Container(
              padding: EdgeInsets.all(context.wp(2.5)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.settings,
                color: AppColors.black,
                size: context.wp(5),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle(!isMonthlyView);
            },
            child: Container(
              padding: EdgeInsets.all(context.wp(2.5)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isMonthlyView ? LucideIcons.calendar : LucideIcons.calendarDays,
                color: AppColors.black,
                size: context.wp(5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
