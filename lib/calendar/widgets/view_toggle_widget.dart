import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class ViewToggleWidget extends StatelessWidget {
  final bool isMonthlyView;
  final Function(bool) onToggle;

  const ViewToggleWidget({
    Key? key,
    required this.isMonthlyView,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.wp(4),
        vertical: context.hp(2),
      ),
      child: Row(
        children: [
          Text('캘린더', style: AppTextStyle.title),
          Spacer(),
          Wrap(
            spacing: 8,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle(true);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: context.hp(1.5),
                    horizontal: context.wp(6),
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMonthlyView
                            ? Colors.pinkAccent.shade100
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '월간',
                      style: AppTextStyle.body.copyWith(
                        fontWeight:
                            isMonthlyView ? FontWeight.bold : FontWeight.normal,
                        color: isMonthlyView ? Colors.white : AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle(false);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: context.hp(1.5),
                    horizontal: context.wp(6),
                  ),
                  decoration: BoxDecoration(
                    color:
                        !isMonthlyView
                            ? Colors.pinkAccent.shade100
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '연간',
                      style: AppTextStyle.body.copyWith(
                        fontWeight:
                            !isMonthlyView
                                ? FontWeight.bold
                                : FontWeight.normal,
                        color: !isMonthlyView ? Colors.white : AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
