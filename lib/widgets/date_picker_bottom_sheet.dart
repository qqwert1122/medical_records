import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:table_calendar/table_calendar.dart';

class DatePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;

  const DatePickerBottomSheet({required this.initialDate});

  @override
  State<DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  late DateTime selectedDate;
  late DateTime focusedDay;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    focusedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(80),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildTitle(),
          SizedBox(height: context.hp(2)),
          _buildCalendar(),
          const Spacer(),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: context.wp(20),
      height: context.hp(0.8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.grey,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Text('날짜 선택', style: AppTextStyle.subTitle);
  }

  Widget _buildCalendar() {
    return StatefulBuilder(
      builder: (context, setState) {
        return SizedBox(
          height: context.hp(50),
          child: TableCalendar<dynamic>(
            firstDay: DateTime(2020),
            lastDay: DateTime.now(),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTextStyle.subTitle,
            ),
            daysOfWeekHeight: context.hp(3),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(10),
              cellPadding: const EdgeInsets.all(0),
              todayDecoration: const BoxDecoration(shape: BoxShape.circle),
              todayTextStyle: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w900,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusDay) {
              setState(() {
                selectedDate = selectedDay;
                focusedDay = focusDay;
              });
            },
            onPageChanged: (focusDay) {
              setState(() {
                focusedDay = focusDay;
              });
            },
            locale: 'ko_KR',
          ),
        );
      },
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '취소',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        SizedBox(width: context.wp(4)),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(selectedDate);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '확인',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
