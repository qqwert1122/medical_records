import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/components/drag_handle.dart';
import 'package:medical_records/features/calendar/widgets/calendar_record_detail.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:intl/intl.dart';

class RecordDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> record;
  final List<Map<String, dynamic>> histories;
  final List<Map<String, dynamic>> images;
  final List<String> memos;
  final VoidCallback? onDataUpdated;

  const RecordDetailBottomSheet({
    Key? key,
    required this.record,
    required this.histories,
    required this.images,
    required this.memos,
    this.onDataUpdated,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> record,
    required List<Map<String, dynamic>> histories,
    required List<Map<String, dynamic>> images,
    required List<String> memos,
    VoidCallback? onDataUpdated,
  }) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => RecordDetailBottomSheet(
            record: record,
            histories: histories,
            images: images,
            memos: memos,
            onDataUpdated: onDataUpdated,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          DragHandle(), // 상단 헤더
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text(
                      record['symptom_name'] ?? '증상 없음',
                      style: AppTextStyle.subTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '|',
                      style: AppTextStyle.subTitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      record['spot_name'] ?? '부위 없음',
                      style: AppTextStyle.subTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '|',
                      style: AppTextStyle.subTitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getDateRangeText(),
                      style: AppTextStyle.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '|',
                      style: AppTextStyle.subTitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // CalendarRecordDetail 내용
          Expanded(
            child: CalendarRecordDetail(
              record: record,
              histories: histories,
              images: images,
              memos: memos,
              onBackPressed: () => Navigator.of(context).pop(),
              pageIndex: 0,
              onDataUpdated: onDataUpdated,
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeText() {
    final startDate = DateTime.parse(record['start_date']);
    final endDate =
        record['end_date'] != null ? DateTime.parse(record['end_date']) : null;

    if (endDate != null) {
      return '${DateFormat('MM.dd').format(startDate)} ~ ${DateFormat('MM.dd').format(endDate)}';
    } else {
      return '${DateFormat('MM.dd').format(startDate)} ~';
    }
  }

  Widget _buildStatusBadge() {
    final endDate = record['end_date'];

    String status;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (endDate != null) {
      status = '완료';
      backgroundColor = AppColors.backgroundSecondary;
      textColor = AppColors.textPrimary;
      icon = LucideIcons.checkCircle;
    } else {
      status = '진행중';
      backgroundColor = Colors.blueAccent;
      textColor = AppColors.white;
      icon = LucideIcons.circleDashed;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          SizedBox(width: 4),
          Text(
            status,
            style: AppTextStyle.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
