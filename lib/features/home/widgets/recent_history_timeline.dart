import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:timeline_tile/timeline_tile.dart';

class RecentHistoryTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> recentHistory;
  final VoidCallback onMorePressed;

  const RecentHistoryTimeline({
    super.key,
    required this.recentHistory,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 히스토리',
            style: AppTextStyle.subTitle.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          recentHistory.isEmpty
              ? Container(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '최근 히스토리가 없습니다',
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
              : _buildHistoryTimeline(),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onMorePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '더 보기',
                style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline() {
    return Container(
      height: 400,
      child: ListView.builder(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        itemCount: recentHistory.length,
        itemBuilder: (context, index) {
          final event = recentHistory[index];
          final eventDate = DateTime.parse(event['date']).toLocal();
          final currentDate = TimeFormat.getDate(event['date']);
          final previousDate =
              index > 0
                  ? TimeFormat.getDate(recentHistory[index - 1]['date'])
                  : '';

          final color =
              event['type'] == 'symptom'
                  ? Color(int.parse(event['color']))
                  : _getEventTypeColor(event['type']);

          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.2,
            isFirst: index == 0,
            isLast: index == recentHistory.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 16,
              height: 16,
              indicator: Container(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Icon(
                    _getEventTypeIcon(event),
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              ),
            ),
            beforeLineStyle: LineStyle(
              color: AppColors.backgroundSecondary,
              thickness: 2,
            ),
            afterLineStyle: LineStyle(
              color: AppColors.backgroundSecondary,
              thickness: 2,
            ),
            startChild: Padding(
              padding: EdgeInsets.only(right: 8),
              child:
                  currentDate != previousDate
                      ? Text(
                        TimeFormat.getDate(event['date']),
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      )
                      : SizedBox(height: 0),
            ),
            endChild: Container(
              padding: EdgeInsets.only(left: 12, bottom: 16, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event['title'] ?? '기록',
                          style: AppTextStyle.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimeOnly(eventDate),
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (event['subtitle'] != null && event['subtitle'].isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        event['subtitle'],
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getEventTypeLabel(event),
                        style: AppTextStyle.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimeOnly(DateTime date) {
    return '${date.hour}시 ${date.minute}분';
  }

  IconData _getEventTypeIcon(Map<String, dynamic> event) {
    final type = event['type'];
    switch (type) {
      case 'symptom':
        return LucideIcons.alertCircle;
      case 'INITIAL':
        return LucideIcons.circleDashed;
      case 'PROGRESS':
        return LucideIcons.arrowRight;
      case 'TREATMENT':
        return LucideIcons.heart;
      case 'COMPLETE':
        return LucideIcons.checkCircle;
      default:
        return LucideIcons.circle;
    }
  }

  String _getEventTypeLabel(Map<String, dynamic> event) {
    final type = event['type'];
    switch (type) {
      case 'symptom':
        return '증상';
      case 'INITIAL':
        return '증상';
      case 'PROGRESS':
        return '경과';
      case 'TREATMENT':
        return '치료';
      case 'COMPLETE':
        return '완료';
      default:
        return '기록';
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'symptom':
        return Colors.redAccent;
      case 'INITIAL':
        return Colors.redAccent;
      case 'PROGRESS':
        return Colors.blueAccent;
      case 'TREATMENT':
        return Colors.pinkAccent;
      case 'COMPLETE':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }
}
