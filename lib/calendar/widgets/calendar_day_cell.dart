import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final List<Color> recordColors;

  const CalendarDayCell({
    Key? key,
    required this.day,
    required this.isSelected,
    this.isToday = false,
    required this.recordColors,
  }) : super(key: key);

  Widget _buildRecordIndicator() {
    return Container(
      height: 24,
      width: 24,
      alignment: Alignment.center,
      child: _buildIndicatorContent(),
    );
  }

  Widget _buildIndicatorContent() {
    if (recordColors.isEmpty) return const SizedBox();

    if (recordColors.length == 1) {
      return Container(
        height: 8,
        width: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: recordColors[0],
        ),
      );
    } else if (recordColors.length == 2) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(2, 2),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[1],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-2, -2),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[0],
              ),
            ),
          ),
        ],
      );
    } else if (recordColors.length == 3) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(4, 0),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[2],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, 0),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[1],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-4, 0),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[0],
              ),
            ),
          ),
        ],
      );
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(2, 2),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[3],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-2, 2),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[2],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(2, -2),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[1],
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-2, -2),
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recordColors[0],
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
            style: AppTextStyle.body.copyWith(
              fontWeight:
                  isSelected || isToday ? FontWeight.w900 : FontWeight.normal,
              color:
                  isSelected
                      ? Colors.pinkAccent
                      : isToday
                      ? Colors.blueAccent
                      : AppColors.black,
            ),
          ),
        ),
        Expanded(child: Center(child: _buildRecordIndicator())),
      ],
    );
  }
}
