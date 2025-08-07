import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class YearlyCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, String> dayImages;
  final Function(DateTime) onDaySelected;

  const YearlyCalendar({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.dayImages,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final year = focusedDay.year;

    return LayoutBuilder(
      // LayoutBuilder로 감싸기
      builder: (context, constraints) {
        final itemHeight = constraints.maxHeight / 3; // 화면 높이를 3으로 나눔

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: context.wp(2),
            right: context.wp(2),
            top: context.hp(1),
            bottom: context.hp(10),
          ),
          child: Column(
            children: List.generate(6, (rowIndex) {
              return SizedBox(
                height: itemHeight, // 고정 높이 설정
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMonthGrid(context, year, rowIndex * 2 + 1),
                    ),
                    SizedBox(width: context.wp(2)),
                    Expanded(
                      child: _buildMonthGrid(context, year, rowIndex * 2 + 2),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildMonthGrid(BuildContext context, int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Text(
          '$month월',
          style: AppTextStyle.body.copyWith(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: 42, // 6주 * 7일
            itemBuilder: (context, index) {
              final dayNumber = index - firstWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return SizedBox();
              }

              final currentDate = DateTime(year, month, dayNumber);
              final hasImage = dayImages.containsKey(currentDate);
              final isSelected = isSameDay(selectedDay, currentDate);
              final isToday = isSameDay(DateTime.now(), currentDate);

              return GestureDetector(
                onTap: () => onDaySelected(currentDate),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        hasImage
                            ? Colors.green.withValues(alpha: 0.9)
                            : isSelected
                            ? Colors.pinkAccent.withValues(alpha: 0.1)
                            : isToday
                            ? Colors.blueAccent.withValues(alpha: 0.4)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isSelected
                            ? Border.all(
                              color: Colors.pinkAccent.withValues(alpha: 0.1),
                              width: 1,
                            )
                            : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
