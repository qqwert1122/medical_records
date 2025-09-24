import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/components/drag_handle.dart';

class MonthPickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final bool isMonthlyView;

  const MonthPickerBottomSheet({
    Key? key,
    required this.initialDate,
    this.isMonthlyView = true,
  }) : super(key: key);

  @override
  State<MonthPickerBottomSheet> createState() => _MonthPickerBottomSheetState();
}

class _MonthPickerBottomSheetState extends State<MonthPickerBottomSheet> {
  late DateTime tempDate;

  @override
  void initState() {
    super.initState();
    tempDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(40),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          DragHandle(),
          SizedBox(height: context.hp(1)),
          Text(
            widget.isMonthlyView ? '월 선택' : '연도 선택',
            style: AppTextStyle.subTitle.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: context.hp(1)),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 년도 피커
                      SizedBox(
                        width: context.wp(40),
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: tempDate.year - 2020,
                          ),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.lightImpact();
                            if (mounted) {
                              setState(() {
                                tempDate = DateTime(
                                  2020 + index,
                                  tempDate.month,
                                );
                              });
                            }
                          },
                          children: List.generate(11, (index) {
                            bool isSelected = index == tempDate.year - 2020;
                            return Center(
                              child: Text(
                                '${2020 + index}년',
                                style: AppTextStyle.body.copyWith(
                                  color:
                                      isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      if (widget.isMonthlyView) ...[
                        SizedBox(width: context.wp(5)),
                        // 월 피커
                        SizedBox(
                          width: context.wp(40),
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: tempDate.month - 1,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              HapticFeedback.lightImpact();
                              if (mounted) {
                                setState(() {
                                  tempDate = DateTime(tempDate.year, index + 1);
                                });
                              }
                            },
                            children: List.generate(12, (index) {
                              bool isSelected = index == tempDate.month - 1;
                              return Center(
                                child: Text(
                                  '${index + 1}월',
                                  style: AppTextStyle.body.copyWith(
                                    color:
                                        isSelected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.wp(4)),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, tempDate);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, context.hp(6)),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '확인',
                style: AppTextStyle.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
