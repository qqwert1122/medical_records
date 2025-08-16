import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:table_calendar/table_calendar.dart';

class DateTimePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? minDate;

  const DateTimePickerBottomSheet({required this.initialDate, this.minDate});

  @override
  State<DateTimePickerBottomSheet> createState() =>
      _DateTimePickerBottomSheetState();
}

class _DateTimePickerBottomSheetState extends State<DateTimePickerBottomSheet> {
  late DateTime selectedDate;
  late int selectedHour;
  late int selectedMinute;

  late DateTime _baseDate;
  final int _totalDays = 730;
  final int _centerIndex = 365;
  int _currentSelectedIndex = 365;

  late FixedExtentScrollController dayController;
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedHour = widget.initialDate.hour;
    selectedMinute = widget.initialDate.minute;

    _baseDate = DateTime(
      widget.minDate?.year ?? widget.initialDate.year,
      widget.minDate?.month ?? widget.initialDate.month,
      widget.minDate?.day ?? widget.initialDate.day,
    );

    _currentSelectedIndex =
        widget.minDate != null
            ? widget.initialDate.difference(widget.minDate!).inDays
            : _centerIndex;

    dayController = FixedExtentScrollController(
      initialItem: _currentSelectedIndex,
    );
    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  void dispose() {
    dayController.dispose();
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSameAsMinDate =
        widget.minDate != null &&
        DateUtils.isSameDay(selectedDate, widget.minDate!);

    return Container(
      height: context.hp(40),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: context.paddingHorizSM,
      child: Column(
        children: [
          _buildDragHandle(),
          _buildTitle(),
          SizedBox(height: context.hp(2)),
          Expanded(
            child: Row(
              children: [
                // 날짜 피커
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text('날짜', style: AppTextStyle.caption),
                      SizedBox(height: context.hp(1)),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: dayController,
                          itemExtent: 50,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.lightImpact();
                            final dayDiff = index - _centerIndex;
                            final newDate = _baseDate.add(
                              Duration(days: dayDiff),
                            );
                            setState(() {
                              _currentSelectedIndex = index;
                              selectedDate = DateTime(
                                newDate.year,
                                newDate.month,
                                newDate.day,
                                selectedHour,
                                selectedMinute,
                              );
                            });
                          },
                          children: List.generate(_totalDays, (index) {
                            final dayDiff = index - _centerIndex;
                            final date = _baseDate.add(Duration(days: dayDiff));
                            final isToday = DateUtils.isSameDay(
                              date,
                              DateTime.now(),
                            );
                            final isSelected = index == _currentSelectedIndex;

                            return Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                children: [
                                  Text(
                                    '${date.year.toString().padLeft(4, '0')}년 ${date.month}월 ${date.day}일',
                                    style: AppTextStyle.body.copyWith(
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isSelected
                                              ? AppColors.black
                                              : AppColors.grey,
                                    ),
                                  ),
                                  if (isToday)
                                    Text(
                                      '오늘',
                                      style: AppTextStyle.caption.copyWith(
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color: Colors.pinkAccent,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.wp(2)),
                // 시간 피커
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text('시', style: AppTextStyle.caption),
                      SizedBox(height: context.hp(1)),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: hourController,
                          itemExtent: 50,
                          onSelectedItemChanged: (index) {
                            if (isSameAsMinDate &&
                                index < widget.minDate!.hour) {
                              return;
                            }
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedHour = index;
                              if (isSameAsMinDate &&
                                  selectedHour == widget.minDate!.hour &&
                                  selectedMinute < widget.minDate!.minute) {
                                selectedMinute = widget.minDate!.minute;
                              }
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedHour,
                                selectedMinute,
                              );
                            });
                          },
                          children: List.generate(24, (index) {
                            bool isSelected = selectedHour == index;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: AppTextStyle.body.copyWith(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.black
                                          : AppColors.grey,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.wp(2)),
                // 분 피커
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text('분', style: AppTextStyle.caption),
                      SizedBox(height: context.hp(1)),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: minuteController,
                          itemExtent: 50,
                          onSelectedItemChanged: (index) {
                            if (isSameAsMinDate &&
                                selectedHour == widget.minDate!.hour &&
                                index < widget.minDate!.minute) {
                              return;
                            }
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedMinute = index;
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedHour,
                                selectedMinute,
                              );
                            });
                          },
                          children: List.generate(60, (index) {
                            bool isSelected = selectedMinute == index;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: AppTextStyle.body.copyWith(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.black
                                          : AppColors.grey,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildButtons(),
          SizedBox(height: context.hp(1)),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: context.wp(15),
      height: context.hp(0.5),
      margin: EdgeInsets.symmetric(vertical: context.hp(1.5)),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildTitle() {
    return Text('날짜 선택', style: AppTextStyle.subTitle);
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
              backgroundColor: AppColors.surface,
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
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '확인',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
