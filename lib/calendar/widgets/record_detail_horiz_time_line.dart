import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:timeline_tile/timeline_tile.dart';

class RecordDetailHorizTimeLine extends StatelessWidget {
  final List<Map<String, dynamic>> histories;
  const RecordDetailHorizTimeLine({super.key, required this.histories});

  @override
  Widget build(BuildContext context) {
    String? getLatestDateForEventType(String eventType) {
      final filteredHistories =
          histories.where((h) => h['event_type'] == eventType).toList();
      if (filteredHistories.isEmpty) return null;
      filteredHistories.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['record_date'] ?? '');
          final dateB = DateTime.parse(b['record_date'] ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
      return filteredHistories.first['record_date'];
    }

    final sortedHistories = List<Map<String, dynamic>>.from(histories)
      ..sort((a, b) {
        try {
          final dateA = DateTime.parse(a['record_date'] ?? '');
          final dateB = DateTime.parse(b['record_date'] ?? '');
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

    final List<Map<String, dynamic>> timelineItems = [];

    timelineItems.add({
      'type': 'INITIAL',
      'label': '시작',
      'checked': sortedHistories.any((h) => h['event_type'] == 'INITIAL'),
      'date': getLatestDateForEventType('INITIAL'),
    });

    for (var history in sortedHistories) {
      if (history['event_type'] == 'TREATMENT' ||
          history['event_type'] == 'PROGRESS') {
        timelineItems.add({
          'type': history['event_type'],
          'label': history['event_type'] == 'TREATMENT' ? '치료' : '경과',
          'checked': true,
          'date': history['record_date'],
        });
      }
    }

    timelineItems.add({
      'type': 'COMPLETE',
      'label': '종료',
      'checked': sortedHistories.any((h) => h['event_type'] == 'COMPLETE'),
      'date': getLatestDateForEventType('COMPLETE'),
    });

    final isCompleted =
        timelineItems.first['checked'] == true &&
        timelineItems.last['checked'] == true;

    return Container(
      decoration: BoxDecoration(color: AppColors.background),
      child: Padding(
        padding: EdgeInsets.only(
          left: 8.0,
          right: timelineItems.length <= 4 ? 8 : 0,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child:
                  timelineItems.length <= 4
                      ? Row(
                        children: List.generate(timelineItems.length, (index) {
                          return Expanded(
                            // Expanded로 감싸서 화면 너비에 맞춤
                            child: buildTimelineTile(
                              context,
                              timelineItems,
                              index,
                              isCompleted,
                            ),
                          );
                        }),
                      )
                      : ListView.builder(
                        // 항목이 4개를 초과하면 스크롤 가능
                        scrollDirection: Axis.horizontal,
                        itemCount: timelineItems.length,
                        itemBuilder: (context, index) {
                          return buildTimelineTile(
                            context,
                            timelineItems,
                            index,
                            isCompleted,
                          );
                        },
                      ),
            ),
            SizedBox(height: context.hp(3)),
          ],
        ),
      ),
    );
  }

  Widget buildTimelineTile(
    BuildContext context,
    List<Map<String, dynamic>> timelineItems,
    int index,
    bool isCompleted,
  ) {
    final item = timelineItems[index];
    final time = TimeFormat.getDate(item['date'] as String?);
    final isChecked = item['checked'] == true;
    final isFirst = index == 0;
    final isLast = index == timelineItems.length - 1;

    final Color beforeLineColor =
        isCompleted ||
                (!isFirst &&
                    timelineItems[index - 1]['checked'] == true &&
                    isChecked)
            ? Colors.blueAccent
            : AppColors.backgroundSecondary;

    final bool nextItemChecked =
        !isLast && timelineItems[index + 1]['checked'] == true;
    final Color afterLineColor =
        isCompleted || (isChecked && nextItemChecked)
            ? Colors.blueAccent
            : AppColors.backgroundSecondary;

    return TimelineTile(
      axis: TimelineAxis.horizontal,
      alignment: TimelineAlign.center,
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 50,
        height: 50,
        indicator: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isChecked ? Colors.blueAccent : AppColors.backgroundSecondary,
            border: Border.all(color: AppColors.background, width: 8),
          ),
          child:
              isChecked
                  ? Icon(LucideIcons.check, color: AppColors.white, size: 24)
                  : null,
        ),
      ),
      beforeLineStyle: LineStyle(color: beforeLineColor, thickness: 2),
      afterLineStyle: LineStyle(color: afterLineColor, thickness: 2),
      endChild: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              item['label'] as String,
              style: AppTextStyle.caption.copyWith(
                color:
                    isChecked
                        ? AppColors.textPrimary
                        : AppColors.lightGrey.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (time.isNotEmpty)
              Text(
                time,
                style: AppTextStyle.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
