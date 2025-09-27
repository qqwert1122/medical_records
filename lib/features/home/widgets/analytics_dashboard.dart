import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/components/summary_card.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class AnalyticsDashboard extends StatelessWidget {
  final int totalRecords;
  final int activeRecords;
  final int completedRecords;
  final double averageDuration;
  final VoidCallback onAnalysisPressed;
  final VoidCallback onHistoryPressed;

  const AnalyticsDashboard({
    super.key,
    required this.totalRecords,
    required this.activeRecords,
    required this.completedRecords,
    required this.averageDuration,
    required this.onAnalysisPressed,
    required this.onHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildSummaryCards()],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: '전체 기록',
                value: '${totalRecords}건',
                icon: LucideIcons.galleryVerticalEnd,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: '진행 중',
                value: '${activeRecords}건',
                icon: LucideIcons.circleDashed,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
