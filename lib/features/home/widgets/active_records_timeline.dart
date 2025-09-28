import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/components/record_circle_avatar.dart';
import 'package:medical_records/utils/time_format.dart';

class ActiveRecordsTimeline extends StatefulWidget {
  final List<Map<String, dynamic>> activeRecords;

  const ActiveRecordsTimeline({super.key, required this.activeRecords});

  @override
  State<ActiveRecordsTimeline> createState() => _ActiveRecordsTimelineState();
}

class _ActiveRecordsTimelineState extends State<ActiveRecordsTimeline> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients && widget.activeRecords.isNotEmpty) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeRecords.isEmpty) {
      return SizedBox.shrink();
    }

    // start_date 기준으로 정렬
    final sortedRecords = List<Map<String, dynamic>>.from(widget.activeRecords)
      ..sort((a, b) {
        try {
          final dateA = DateTime.parse(a['start_date']);
          final dateB = DateTime.parse(b['start_date']);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

    return Column(
      children: [
        SizedBox(
          height: 70,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedRecords.length,
            itemBuilder: (context, index) {
              return _buildTimelineTile(context, sortedRecords, index);
            },
          ),
        ),
        SizedBox(height: context.hp(1)),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: _buildScrollIndicator(),
        ),
      ],
    );
  }

  Widget _buildTimelineTile(
    BuildContext context,
    List<Map<String, dynamic>> records,
    int index,
  ) {
    final record = records[index];
    final isFirst = index == 0;
    final isLast = index == records.length - 1;
    final startDate = TimeFormat.getDate(record['start_date']);

    return TimelineTile(
      axis: TimelineAxis.horizontal,
      alignment: TimelineAlign.start,
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: 30,
        height: 30,
        padding: EdgeInsets.all(2),
        indicator: RecordCircleAvatar(
          name: record['symptom_name'] ?? '',
          color: record['color'] ?? '4280391935',
          size: 26,
        ),
      ),
      beforeLineStyle: LineStyle(
        color: isFirst ? Colors.transparent : AppColors.textSecondary,
        thickness: 2,
      ),
      afterLineStyle: LineStyle(
        color: isLast ? Colors.transparent : AppColors.textSecondary,
        thickness: 2,
      ),
      endChild: SizedBox(
        width: 70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 4),
            Text(
              record['symptom_name'] ?? '',
              style: AppTextStyle.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: 2),
            Text(
              startDate,
              style: AppTextStyle.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollIndicator() {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        if (!_scrollController.hasClients) {
          return SizedBox(height: 4);
        }

        try {
          final maxScrollExtent = _scrollController.position.maxScrollExtent;
          final currentOffset = _scrollController.offset;

          // 스크롤할 수 없는 경우 인디케이터 숨김
          if (maxScrollExtent <= 0) {
            return SizedBox(height: 4);
          }

          final indicatorTrackWidth = MediaQuery.of(context).size.width - 80;
          const indicatorThumbWidth = 80.0;

          // 스크롤 진행률 계산
          final progress = (currentOffset / maxScrollExtent).clamp(0.0, 1.0);

          // 썸네일 위치 계산
          final thumbPosition =
              progress * (indicatorTrackWidth - indicatorThumbWidth);

          return Center(
            child: Container(
              width: indicatorTrackWidth,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: thumbPosition,
                    child: Container(
                      width: indicatorThumbWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          return SizedBox(height: 4);
        }
      },
    );
  }
}
