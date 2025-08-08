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
    if (recordColors.isEmpty) return Container();

    if (recordColors.length == 1) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: recordColors[0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Container(color: Colors.transparent)),
                SizedBox(width: 1),
                Expanded(child: Container(color: Colors.transparent)),
              ],
            ),
          ),
        ],
      );
    } else if (recordColors.length == 2) {
      return Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: recordColors[0],
              ),
            ),
          ),
          SizedBox(width: 1),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: recordColors[1],
              ),
            ),
          ),
        ],
      );
    } else if (recordColors.length == 3) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: recordColors[0],
                    ),
                  ),
                ),
                SizedBox(width: 1),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: recordColors[1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: recordColors[2],
                    ),
                  ),
                ),
                SizedBox(width: 1),
                Expanded(child: Container(color: Colors.transparent)),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: recordColors[0],
                    ),
                  ),
                ),
                SizedBox(width: 1),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: recordColors[1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: recordColors[2],
                    ),
                  ),
                ),
                SizedBox(width: 1),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: recordColors[3],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('day: $day, recordColors: $recordColors');

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
                        : recordColors.isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.grey,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              child: _buildRecordIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
