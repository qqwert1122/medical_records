import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarHeaderWidget extends StatefulWidget {
  final bool isMonthlyView;
  final DateTime focusedDay;
  final Function() onDateTap;

  const CalendarHeaderWidget({
    Key? key,
    required this.isMonthlyView,
    required this.focusedDay,
    required this.onDateTap,
  }) : super(key: key);

  @override
  State<CalendarHeaderWidget> createState() => _CalendarHeaderWidgetState();
}

class _CalendarHeaderWidgetState extends State<CalendarHeaderWidget> {
  // count 변수 초기화
  int thisMonthCount = 0;
  int totalLiveCount = 0;
  int treatmentCount = 0;

  bool _isLoadingCounts = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void didUpdateWidget(CalendarHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDay != widget.focusedDay ||
        oldWidget.isMonthlyView != widget.isMonthlyView) {
      _loadCounts();
    }
  }

  Future<void> _loadCounts() async {
    if (_isLoadingCounts) return;
    _isLoadingCounts = true;

    try {
      // 임시 변수 초기화
      int tempThisMonthCount = 0;
      int tempTotalLiveCount = 0;
      int tempTreatmentCount = 0;

      // 해당 월 count
      tempThisMonthCount = await _getMonthlyRecordCount();

      // LiveRecords count
      final liveRecords = await DatabaseService().getLiveRecords();
      tempTotalLiveCount = liveRecords.length;

      for (final record in liveRecords) {
        final histories = await DatabaseService().getHistories(
          record['record_id'],
        );

        if (histories.where((h) => h['event_type'] == 'TREATMENT').length > 0)
          tempTreatmentCount++;
      }

      if (!mounted) return;
      setState(() {
        thisMonthCount = tempThisMonthCount;
        totalLiveCount = tempTotalLiveCount;
        treatmentCount = tempTreatmentCount;
      });
    } finally {
      _isLoadingCounts = false;
    }
  }

  Future<int> _getMonthlyRecordCount() async {
    final DateTime firstDay;
    final DateTime lastDay;

    if (widget.isMonthlyView) {
      // 월별 보기: 해당 월의 첫날과 마지막날
      firstDay = DateTime(widget.focusedDay.year, widget.focusedDay.month, 1);
      lastDay = DateTime(
        widget.focusedDay.year,
        widget.focusedDay.month + 1,
        0,
      );
    } else {
      // 연간 보기: 해당 연도의 1월 1일부터 12월 31일
      firstDay = DateTime(widget.focusedDay.year, 1, 1);
      lastDay = DateTime(widget.focusedDay.year, 12, 31);
    }

    final records = await DatabaseService().getOverlappingRecords(
      startDate: firstDay,
      endDate: lastDay,
    );

    return records.length;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 월 선택 헤더
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.wp(4),
            vertical: context.hp(1.5),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onDateTap,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isMonthlyView
                            ? '${widget.focusedDay.year}년 ${widget.focusedDay.month}월'
                            : '${widget.focusedDay.year}년',
                        style: AppTextStyle.subTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 대시보드
        Expanded(
          child: Container(
            height: 40,
            margin: EdgeInsets.only(
              right: context.wp(4),
              top: context.hp(1.5),
              bottom: context.hp(1.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 5,
              children: [
                _buildStatItem(
                  label: '전체',
                  count: thisMonthCount,
                  color: AppColors.black,
                  icon: LucideIcons.calendar,
                  isSimple: false,
                ),
                _buildStatItem(
                  label: '진행중',
                  count: totalLiveCount,
                  color: Colors.blueAccent,
                  icon: LucideIcons.circleDashed,
                  isSimple: true,
                ),
                _buildStatItem(
                  label: '치료즁',
                  count: treatmentCount,
                  color: AppColors.primary,
                  icon: LucideIcons.heart,
                  isSimple: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isSimple,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 4,
      children: [
        isSimple
            ? Icon(icon, size: 16, color: color)
            : Container(
              padding: EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: AppTextStyle.caption.copyWith(
                  color: AppColors.white,
                  fontSize: 12,
                ),
              ),
            ),

        Text(
          '$count건',
          style: AppTextStyle.subTitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
