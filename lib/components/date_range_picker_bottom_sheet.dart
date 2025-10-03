import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/components/drag_handle.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class DateRangePickerBottomSheet extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const DateRangePickerBottomSheet({Key? key, this.initialDateRange})
    : super(key: key);

  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initialDateRange,
  }) async {
    return await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DateRangePickerBottomSheet(initialDateRange: initialDateRange);
      },
    );
  }

  @override
  State<DateRangePickerBottomSheet> createState() =>
      _DateRangePickerBottomSheetState();
}

class _DateRangePickerBottomSheetState
    extends State<DateRangePickerBottomSheet> {
  late DateTime? tempRangeStart;
  late DateTime? tempRangeEnd;
  late DateTime focusedDay;

  @override
  void initState() {
    super.initState();

    // 초기값 설정
    tempRangeStart =
        widget.initialDateRange?.start ??
        DateTime.now().subtract(const Duration(days: 7));
    tempRangeEnd = widget.initialDateRange?.end ?? DateTime.now();
    focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          _buildTitle(),
          _buildCalendar(),
          const SizedBox(height: 16),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return const DragHandle();
  }

  Widget _buildTitle() {
    return Text(
      '날짜 선택',
      style: AppTextStyle.subTitle.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _buildCalendar() {
    return StatefulBuilder(
      builder: (context, setState) {
        return SizedBox(
          height: 400,
          child: TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime.now().add(const Duration(days: 1)),
            focusedDay: focusedDay,
            rangeStartDay: tempRangeStart,
            rangeEndDay: tempRangeEnd,
            rangeSelectionMode: RangeSelectionMode.enforced,
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTextStyle.body.copyWith(
                letterSpacing: -0.3,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(10),
              cellPadding: const EdgeInsets.all(0),
              rangeHighlightColor: AppColors.primary.withValues(alpha: 0.2),
              rangeStartDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: const BoxDecoration(shape: BoxShape.circle),
              todayTextStyle: AppTextStyle.body.copyWith(
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
                focusedDay = focusDay;
              });
            },
            onRangeSelected: (start, end, focusDay) {
              final localStart =
                  start != null
                      ? DateTime(start.year, start.month, start.day)
                      : null;

              final localEnd =
                  end != null
                      ? DateTime(end.year, end.month, end.day)
                      : localStart;

              setState(() {
                tempRangeStart = localStart;
                tempRangeEnd = localEnd ?? localStart;
                focusedDay = focusDay;
              });
            },
            onPageChanged: (focusDay) {
              this.setState(() {
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
            onPressed: _onCancel,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.backgroundSecondary,
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '취소',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _onConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '확인',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onCancel() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  void _onConfirm() {
    HapticFeedback.lightImpact();
    if (tempRangeStart != null && tempRangeEnd != null) {
      if (tempRangeStart!.isAfter(tempRangeEnd!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('유효하지 않은 날짜 범위입니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      Navigator.of(
        context,
      ).pop(DateTimeRange(start: tempRangeStart!, end: tempRangeEnd!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시작일과 종료일을 모두 선택해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
