import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:io';

class RecordTimeline extends StatelessWidget {
  final Map<String, dynamic> record;
  final List<Map<String, dynamic>> histories;
  final List<Map<String, dynamic>> images;
  final Function(List<Map<String, dynamic>>, int) onImageTap;

  const RecordTimeline({
    super.key,
    required this.record,
    required this.histories,
    required this.images,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (histories.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록 타임라인',
            style: AppTextStyle.subTitle.copyWith(color: AppColors.grey),
          ),
          SizedBox(height: context.hp(1)),
          _buildHistoryTimeline(context),
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: histories.length,
      itemBuilder: (context, index) {
        final history = histories[index];
        final historyDate = DateTime.parse(history['created_at']).toLocal();
        final currentDate = _formatDateOnly(historyDate);
        final previousDate =
            index > 0
                ? _formatDateOnly(
                  DateTime.parse(histories[index - 1]['created_at']).toLocal(),
                )
                : '';

        // 해당 history에 연결된 이미지들 찾기
        final historyImages =
            images
                .where((img) => img['history_id'] == history['history_id'])
                .toList();

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.15,
          isFirst: index == 0,
          isLast: index == histories.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 12,
            height: 12,
            color: _getEventTypeColor(history['event_type']),
            padding: EdgeInsets.symmetric(vertical: 4),
          ),
          beforeLineStyle: LineStyle(
            color: AppColors.grey.withValues(alpha: 0.3),
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: AppColors.grey.withValues(alpha: 0.3),
            thickness: 2,
          ),
          startChild:
              currentDate != previousDate
                  ? Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      currentDate,
                      style: AppTextStyle.caption.copyWith(
                        color: AppColors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  )
                  : null,
          endChild: Container(
            padding: EdgeInsets.only(left: 12, bottom: 16, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 시간
                Text(
                  _formatTimeOnly(historyDate),
                  style: AppTextStyle.caption.copyWith(color: AppColors.grey),
                ),
                SizedBox(height: 4),

                // 이벤트 타입 및 정보
                Text(
                  _getEventTypeLabel(history),
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 메모
                if (history['memo'] != null &&
                    history['memo'].toString().trim().isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(history['memo'], style: AppTextStyle.body),
                ],

                // 치료명
                if (history['treatment_name'] != null &&
                    history['treatment_name'].toString().trim().isNotEmpty) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '치료: ${history['treatment_name']}',
                      style: AppTextStyle.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // 이미지 썸네일
                if (historyImages.isNotEmpty) ...[
                  SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: historyImages.length,
                      itemBuilder: (context, imgIndex) {
                        final imagePath =
                            historyImages[imgIndex]['image_url'] as String;
                        return GestureDetector(
                          onTap:
                              () => onImageTap(
                                images,
                                images.indexOf(historyImages[imgIndex]),
                              ),
                          child: Container(
                            width: 60,
                            height: 60,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 20,
                                      color: Colors.grey[500],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateOnly(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatTimeOnly(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getEventTypeColor(String? eventType) {
    switch (eventType) {
      case 'initial':
        return AppColors.primary;
      case 'progress':
        return Colors.blue;
      case 'treatment':
        return Colors.green;
      case 'complete':
        return Colors.grey;
      default:
        return AppColors.grey;
    }
  }

  String _getEventTypeLabel(Map<String, dynamic> history) {
    final eventType = history['event_type'];

    switch (eventType) {
      case 'initial':
        String label = '최초 기록';
        if (record['spot_name'] != null) {
          label += ' - ${record['spot_name']}';
        }
        if (record['symptom_name'] != null) {
          label += ' (${record['symptom_name']})';
        }
        return label;
      case 'progress':
        return '경과 기록';
      case 'treatment':
        return '치료 기록';
      case 'complete':
        return '완료';
      default:
        return eventType ?? '기록';
    }
  }
}
