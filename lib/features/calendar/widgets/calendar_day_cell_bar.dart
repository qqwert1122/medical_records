import 'package:flutter/material.dart';
import 'package:medical_records/features/calendar/widgets/weekly_record_overlay.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarDayCellBar extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final List<Color> recordColors;
  final bool isOutside;
  final Map<int, RecordInfo>? weekRecordSlots;
  final Map<int, RecordInfo>? previousDaySlots;
  final Map<int, RecordInfo>? nextDaySlots;
  final Map<String, DateTime>? recordStartDates;
  final Map<String, DateTime>? recordEndDates;

  const CalendarDayCellBar({
    Key? key,
    required this.day,
    required this.isSelected,
    this.isToday = false,
    required this.recordColors,
    required this.isOutside,
    this.weekRecordSlots,
    this.previousDaySlots,
    this.nextDaySlots,
    this.recordStartDates,
    this.recordEndDates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // extraCount 계산
    final extraCount = (weekRecordSlots?.length ?? 0) - 4;

    Color _getTextColor() {
      if (isOutside) return AppColors.textSecondary;
      if (isSelected) return AppColors.primary;
      if (isToday) return Colors.blueAccent;
      if (day.isAfter(DateTime.now().subtract(Duration(days: 1))) && !isToday) {
        return AppColors.textSecondary;
      }
      return AppColors.textPrimary;
    }

    return Column(
      children: [
        SizedBox(
          height: 28.0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected || isToday
                          ? FontWeight.w900
                          : FontWeight.normal,
                  color: _getTextColor(),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(), // 막대 영역 (오버레이로 처리)
        ),
        SizedBox(
          height: 12,
          child: Text(
            '+$extraCount',
            style: TextStyle(
              fontSize: 10,
              color:
                  extraCount > 0 ? AppColors.lightGrey : AppColors.background,
            ),
          ),
        ),
      ],
    );
  }
}
