import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarDayCellBar extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final List<Color> recordColors;

  const CalendarDayCellBar({
    Key? key,
    required this.day,
    required this.isSelected,
    this.isToday = false,
    required this.recordColors,
  }) : super(key: key);

  // 버전 2: 막대바 인디케이터
  Widget _buildRecordBarIndicator() {
    if (recordColors.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            recordColors.take(3).map((color) {
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }).toList(),
      ),
    );
  }

  //TODOLIST 막대바 공간 4~5등분 하기

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
        Expanded(child: Center(child: _buildRecordBarIndicator())),
      ],
    );
  }
}
