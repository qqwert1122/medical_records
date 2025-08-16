import 'package:flutter/material.dart';
import 'package:medical_records/calendar/widgets/calendar_day_cell.dart';
import 'package:medical_records/calendar/widgets/calendar_day_cell_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medical_records/styles/app_size.dart';

class MonthlyCalendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, List<Color>> dayRecords;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Function(double)? onHeightChanged;
  final double bottomSheetHeight;

  const MonthlyCalendar({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.dayRecords,
    required this.onDaySelected,
    required this.onPageChanged,
    this.onHeightChanged,
    this.bottomSheetHeight = 0.0,
  }) : super(key: key);

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final calendarHeightFactor = widget.bottomSheetHeight > 0 ? 0.5 : 1.0;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
            child: TableCalendar(
              key: ValueKey(calendarHeightFactor),
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: widget.focusedDay,
              calendarFormat: widget.calendarFormat,
              selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                widget.onDaySelected(selectedDay, focusedDay);
                widget.onHeightChanged?.call(0.5);
              },
              onPageChanged: widget.onPageChanged,
              headerVisible: false,
              daysOfWeekHeight: context.hp(3.5),
              rowHeight:
                  calendarHeightFactor == 1.0 ? context.hp(13) : context.hp(5),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final colors =
                      widget.dayRecords[DateTime(
                        day.toLocal().year,
                        day.toLocal().month,
                        day.toLocal().day,
                      )] ??
                      [];

                  return calendarHeightFactor == 1.0
                      ? CalendarDayCellBar(
                        day: day,
                        isSelected: false,
                        recordColors: colors,
                      )
                      : CalendarDayCell(
                        day: day,
                        isSelected: false,
                        recordColors: colors,
                      );
                },
                selectedBuilder: (context, day, focusedDay) {
                  final colors =
                      widget.dayRecords[DateTime(
                        day.toLocal().year,
                        day.toLocal().month,
                        day.toLocal().day,
                      )] ??
                      [];

                  return calendarHeightFactor == 1.0
                      ? CalendarDayCellBar(
                        day: day,
                        isSelected: true,
                        recordColors: colors,
                      )
                      : CalendarDayCell(
                        day: day,
                        isSelected: true,
                        recordColors: colors,
                      );
                },
                todayBuilder: (context, day, focusedDay) {
                  final colors =
                      widget.dayRecords[DateTime(
                        day.toLocal().year,
                        day.toLocal().month,
                        day.toLocal().day,
                      )] ??
                      [];

                  return calendarHeightFactor == 1.0
                      ? CalendarDayCellBar(
                        day: day,
                        isSelected: false,
                        isToday: true,
                        recordColors: colors,
                      )
                      : CalendarDayCell(
                        day: day,
                        isSelected: false,
                        isToday: true,
                        recordColors: colors,
                      );
                },
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.redAccent),
                cellMargin: EdgeInsets.all(0),
              ),
              locale: 'ko_KR',
            ),
          ),
        ),
      ],
    );
  }
}
