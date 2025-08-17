import 'package:flutter/material.dart';
import 'package:medical_records/calendar/widgets/weekly_record_overlay.dart';
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

  Widget _buildWeekRecordBars() {
    if (weekRecordSlots == null || weekRecordSlots!.isEmpty) {
      return const SizedBox();
    }

    final visibleSlots = weekRecordSlots!.entries.take(4).toList();
    final extraCount = weekRecordSlots!.length - 4;
    final dateKey = DateTime(day.year, day.month, day.day);

    return Column(
      children: [
        Expanded(
          child: Column(
            children: List.generate(4, (index) {
              final slot = visibleSlots.firstWhere(
                (e) => e.key == index,
                orElse:
                    () => MapEntry(
                      index,
                      RecordInfo(
                        recordId: '',
                        title: '',
                        color: Colors.transparent,
                      ),
                    ),
              );

              if (slot.value.recordId.isEmpty) {
                return Expanded(child: SizedBox());
              }

              final recordId = slot.value.recordId;
              final color = slot.value.color;

              // 같은 record_id로 연결 여부 확인
              final hasPrevConnection =
                  previousDaySlots?.containsKey(index) == true &&
                  previousDaySlots![index]!.recordId == recordId;
              final hasNextConnection =
                  nextDaySlots?.containsKey(index) == true &&
                  nextDaySlots![index]!.recordId == recordId;

              // 실제 시작/종료 날짜 확인
              final isRecordStart = recordStartDates?[recordId] == dateKey;
              final isRecordEnd = recordEndDates?[recordId] == dateKey;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    top: 1,
                    bottom: 1,
                    left: (hasPrevConnection && day.weekday != 7) ? 0 : 2,
                    right: (hasNextConnection && day.weekday != 6) ? 0 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(
                        (isRecordStart || day.weekday == 7) ? 4 : 0,
                      ),
                      right: Radius.circular(
                        (isRecordEnd || day.weekday == 6) ? 4 : 0,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(
          height: 12,
          child: Text(
            '+$extraCount',
            style: TextStyle(
              fontSize: 10,
              color: extraCount > 0 ? Colors.grey : AppColors.background,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // extraCount 계산
    final extraCount = (weekRecordSlots?.length ?? 0) - 4;

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
                        ? Colors.pinkAccent.withValues(alpha: 0.1)
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
                  color:
                      isOutside
                          ? Colors.grey
                          : isSelected
                          ? Colors.pinkAccent
                          : isToday
                          ? Colors.blueAccent
                          : Colors.black,
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
              color: extraCount > 0 ? Colors.grey : AppColors.background,
            ),
          ),
        ),
      ],
    );
  }
}
