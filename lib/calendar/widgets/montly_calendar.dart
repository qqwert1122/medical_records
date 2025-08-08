import 'package:flutter/material.dart';
import 'package:medical_records/calendar/widgets/calendar_day_cell.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medical_records/styles/app_size.dart';

class MonthlyCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, List<Color>> dayRecords;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;

  const MonthlyCalendar({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.dayRecords,
    required this.onDaySelected,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('dayrecords in montlycalendar : $dayRecords');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: focusedDay,
        calendarFormat: calendarFormat,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        headerVisible: false,
        daysOfWeekHeight: context.hp(3.5),
        rowHeight: context.hp(8),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return CalendarDayCell(
              day: day,
              isSelected: false,
              recordColors:
                  dayRecords[DateTime(
                    day.toLocal().year,
                    day.toLocal().month,
                    day.toLocal().day,
                  )] ??
                  [],
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return CalendarDayCell(
              day: day,
              isSelected: true,
              recordColors:
                  dayRecords[DateTime(
                    day.toLocal().year,
                    day.toLocal().month,
                    day.toLocal().day,
                  )] ??
                  [],
            );
          },
          todayBuilder: (context, day, focusedDay) {
            return CalendarDayCell(
              day: day,
              isSelected: false,
              isToday: true,
              recordColors:
                  dayRecords[DateTime(
                    day.toLocal().year,
                    day.toLocal().month,
                    day.toLocal().day,
                  )] ??
                  [],
            );
          },
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red),
        ),
        locale: 'ko_KR',
      ),
    );
  }
}
