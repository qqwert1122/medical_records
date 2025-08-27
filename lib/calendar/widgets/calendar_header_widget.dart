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
  int recentStartCount = 0;
  int activeCount = 0;
  int initialCount = 0;
  int progressCount = 0;
  int treatmentCount = 0;
  int completeCount = 0;

  bool _isLoadingCounts = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void didUpdateWidget(CalendarHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDay != widget.focusedDay) {
      _loadCounts();
    }
  }

  Future<void> _loadCounts() async {
    if (_isLoadingCounts) return;
    _isLoadingCounts = true;

    try {
      final today = DateTime.now();
      final sevenDaysAgo = today.subtract(const Duration(days: 7));

      final liveRecords = await DatabaseService().getLiveRecords();

      // ← 누적 방지: 로컬 임시 변수로 새로 계산
      int active = liveRecords.length;
      int recent = 0;
      int initial = 0;
      int progress = 0;
      int treatment = 0;
      int complete = 0;

      for (final record in liveRecords) {
        final startDateStr = record['start_date'] as String?;
        if (startDateStr != null) {
          final startDate = DateTime.parse(startDateStr);
          if (startDate.isAfter(sevenDaysAgo) ||
              startDate.isAtSameMomentAs(sevenDaysAgo)) {
            recent++;
          }
        }

        // 최신 history가 맨 앞에 오도록 정렬돼 있어야 합니다.
        // getHistories(recordId)는 내부에서 ORDER BY history_id DESC (또는 created_at DESC) 권장
        final histories = await DatabaseService().getHistories(
          record['record_id'],
        );

        if (histories.isEmpty) continue;

        switch ((histories.first['event_type'] as String?) ?? '') {
          case 'INITIAL':
            initial++;
            break;
          case 'PROGRESS':
            progress++;
            break;
          case 'TREATMENT':
            treatment++;
            break;
          case 'COMPLETE':
            complete++;
            break;
          default:
            // 정의되지 않은 상태는 필요 시 별도 처리
            break;
        }
      }

      if (!mounted) return;
      setState(() {
        activeCount = active;
        recentStartCount = recent;
        initialCount = initial;
        progressCount = progress;
        treatmentCount = treatment;
        completeCount = complete;
      });
    } finally {
      _isLoadingCounts = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 날짜 선택 헤더
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
        Container(
          margin: EdgeInsets.symmetric(horizontal: context.wp(4)),
          padding: EdgeInsets.symmetric(
            horizontal: context.wp(4),
            vertical: context.hp(1),
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.backgroundSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                label: '진행중',
                count: activeCount,
                color: AppColors.primary,
                icon: LucideIcons.plus,
              ),
              _buildStatItem(
                label: '최근 7일',
                count: recentStartCount,
                color: AppColors.primary,
                icon: LucideIcons.plus,
              ),

              _buildStatItem(
                label: '시작',
                count: initialCount,
                color: Colors.orange,
                icon: LucideIcons.activity,
              ),
              _buildStatItem(
                label: '경과',
                count: progressCount,
                color: Colors.orange,
                icon: LucideIcons.activity,
              ),
              _buildStatItem(
                label: '치료중',
                count: treatmentCount,
                color: Colors.orange,
                icon: LucideIcons.activity,
              ),
              _buildStatItem(
                label: '종료',
                count: completeCount,
                color: Colors.orange,
                icon: LucideIcons.activity,
              ),
            ],
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
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyle.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                '$count건',
                style: AppTextStyle.subTitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.backgroundSecondary.withValues(alpha: 0.1),
    );
  }
}
