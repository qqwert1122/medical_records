import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:medical_records/features/home/widgets/active_records_timeline.dart';

class ProgressSection extends StatelessWidget {
  final int activeRecords;
  final List<Map<String, dynamic>> activeRecordsList;

  const ProgressSection({
    super.key,
    required this.activeRecords,
    this.activeRecordsList = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (activeRecordsList.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 0,
          right: 16.0,
          bottom: 16.0,
          top: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                '진행 중 증상 타임라인',
                style: AppTextStyle.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: context.hp(2)),
            ActiveRecordsTimeline(activeRecords: activeRecordsList),
          ],
        ),
      ),
    );
  }
}
