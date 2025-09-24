import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';

class WeeklyRecordOverlay extends StatelessWidget {
  final Map<DateTime, Map<int, RecordInfo>> weekRecordSlots;
  final Map<String, DateTime> recordStartDates;
  final Map<String, DateTime> recordEndDates;
  final Map<String, String> recordTitles;
  final DateTime focusedDay;
  final Animation<double>? animation;

  const WeeklyRecordOverlay({
    Key? key,
    required this.weekRecordSlots,
    required this.recordStartDates,
    required this.recordEndDates,
    required this.recordTitles,
    required this.focusedDay,
    this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (animation != null) {
      return AnimatedBuilder(
        animation: animation!,
        builder: (context, child) => _buildOverlay(context, animation!.value),
      );
    }
    return _buildOverlay(context, 1.0);
  }

  Widget _buildOverlay(BuildContext context, double animationValue) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final rowHeight = context.hp(13); // TableCalendar rowHeight와 동일
        final cellHeight = rowHeight;
        final daysOfWeekHeight = context.hp(2);

        // 현재 월의 주별 레코드 정보 수집
        final List<Widget> overlayWidgets = [];

        // 월의 첫날과 마지막날 계산
        final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
        final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);

        // 캘린더 시작일 (첫 주 일요일)
        final calendarStart = firstDay.subtract(
          Duration(days: firstDay.weekday % 7),
        );

        // 각 주별로 처리
        for (int week = 0; week < 6; week++) {
          final weekStart = calendarStart.add(Duration(days: week * 7));

          // 이 주의 레코드들 수집
          Map<String, List<_RecordPosition>> weekRecords = {};

          for (int day = 0; day < 7; day++) {
            final currentDate = weekStart.add(Duration(days: day));
            final dateKey = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
            );

            final daySlots = weekRecordSlots[dateKey];
            if (daySlots != null) {
              daySlots.forEach((slotIndex, recordInfo) {
                final recordId = recordInfo.recordId;

                if (!weekRecords.containsKey(recordId)) {
                  weekRecords[recordId] = [];
                }

                weekRecords[recordId]!.add(
                  _RecordPosition(
                    day: day,
                    slot: slotIndex,
                    date: dateKey,
                    recordInfo: recordInfo,
                  ),
                );
              });
            }
          }

          // 각 레코드에 대해 오버레이 위젯 생성
          weekRecords.forEach((recordId, positions) {
            if (positions.isEmpty) return;

            // 정렬하여 시작과 끝 찾기
            positions.sort((a, b) => a.day.compareTo(b.day));

            final startDay = positions.first.day;
            final endDay = positions.last.day;
            final slot = positions.first.slot;

            // 이 주에서 처음 시작하거나 일요일인 경우만 텍스트 표시
            final isWeekStart =
                startDay == 0 ||
                recordStartDates[recordId] == positions.first.date;

            // 이 주에서 끝나거나 토요일인 경우 추가
            final isWeekEnd =
                endDay == 6 || recordEndDates[recordId] == positions.last.date;

            if (isWeekStart && slot < 4) {
              const dayNumberHeight = 28.0; // CalendarDayCellBar와 동일
              const bottomHeight = 12.0; // +N 영역

              final barAreaHeight = cellHeight - dayNumberHeight - bottomHeight;
              final barHeight = barAreaHeight / 4;

              final top =
                  daysOfWeekHeight +
                  (week * cellHeight) +
                  dayNumberHeight +
                  (slot * barHeight);

              overlayWidgets.add(
                Positioned(
                  left: cellWidth * startDay + 4,
                  top: top,
                  width: cellWidth * (endDay - startDay + 1) - 8,
                  height: barHeight - 2,
                  child: Opacity(
                    opacity: animationValue,
                    child: Container(
                      decoration: BoxDecoration(
                        color: positions.first.recordInfo.color,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(
                            isWeekStart || startDay == 0 ? 2 : 0,
                          ),
                          right: Radius.circular(
                            isWeekEnd || endDay == 6 ? 2 : 0,
                          ),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        recordTitles[recordId] ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }
          });
        }

        return Stack(children: overlayWidgets);
      },
    );
  }
}

class _RecordPosition {
  final int day;
  final int slot;
  final DateTime date;
  final RecordInfo recordInfo;

  _RecordPosition({
    required this.day,
    required this.slot,
    required this.date,
    required this.recordInfo,
  });
}

class RecordInfo {
  final String recordId;
  final String title;
  final Color color;

  RecordInfo({
    required this.recordId,
    required this.title,
    required this.color,
  });
}
