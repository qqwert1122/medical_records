import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool hasImage;

  const CalendarDayCell({
    Key? key,
    required this.day,
    required this.isSelected,
    this.isToday = false,
    required this.hasImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Colors.pinkAccent.withValues(alpha: 0.1)
                : AppColors.surface,
        border: Border.all(
          color:
              isSelected
                  ? Colors.pinkAccent.withValues(alpha: 0.1)
                  : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            child: Text(
              '${day.day}',
              style: AppTextStyle.body.copyWith(
                fontWeight:
                    isSelected || isToday ? FontWeight.w900 : FontWeight.normal,
                color:
                    isSelected
                        ? Colors.pinkAccent
                        : isToday
                        ? Colors.blueAccent
                        : hasImage
                        ? AppColors.textPrimary
                        : AppColors.grey,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    hasImage
                        ? AppColors.grey.withValues(alpha: 0.3)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child:
                  hasImage
                      ? Icon(Icons.image, size: 20, color: AppColors.grey)
                      : null,

              // Image.asset(
              //   'assets/icons/bone_nobg.png',
              //   width: 45,
              //   height: 45,
              // ),
            ),
          ),
        ],
      ),
    );
  }
}
