import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/histories/widgets/add_history_bottom_sheet.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:io';

class RecordDetailTimeline extends StatefulWidget {
  final Map<String, dynamic> record;
  final List<Map<String, dynamic>> histories;
  final List<Map<String, dynamic>> images;
  final Function(List<Map<String, dynamic>>, int) onImageTap;
  final VoidCallback? onHistoryAdded;

  const RecordDetailTimeline({
    super.key,
    required this.record,
    required this.histories,
    required this.images,
    required this.onImageTap,
    this.onHistoryAdded,
  });

  @override
  State<RecordDetailTimeline> createState() => _RecordDetailTimelineState();
}

class _RecordDetailTimelineState extends State<RecordDetailTimeline> {
  bool _showActions = false;

  Future<void> _showAddHistoryBottomSheet(String recordType) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddHistoryBottomSheet(
            recordId: widget.record['record_id'],
            recordType: recordType,
            minDate: DateTime.parse(
              widget.record['start_date'],
            ), // 증상 시작일을 최소 날짜로 설정
          ),
    );

    if (result == true) {
      widget.onHistoryAdded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.histories.isEmpty) {
      return SizedBox.shrink();
    }

    final sortedHistories = List<Map<String, dynamic>>.from(widget.histories)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['record_date']);
        final dateB = DateTime.parse(b['record_date']);
        return dateA.compareTo(dateB);
      });

    return Container(
      decoration: BoxDecoration(color: AppColors.background),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.hp(1)),
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    '타임라인',
                    style: AppTextStyle.subTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: context.wp(4),
                top: 0,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  color: AppColors.surface,

                  onSelected: (String result) {
                    // 선택된 메뉴 아이템에 따라 다른 동작을 수행
                    // 예를 들어 'edit'을 선택하면 수정 함수를 호출
                    setState(() {
                      _showActions = !_showActions;
                    });
                  },
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Text(
                            '수정하기',
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(
                            '삭제하기',
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ),
          _buildHistoryTimeline(context, sortedHistories),
          Padding(
            padding: context.paddingSM,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showAddHistoryBottomSheet('PROGRESS');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.indigoAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '경과 기록',
                          style: AppTextStyle.body.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _showAddHistoryBottomSheet('TREATMENT');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '치료 기록',
                          style: AppTextStyle.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (widget.record['status'] != 'COMPLETE')
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showAddHistoryBottomSheet('COMPLETE');
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, context.hp(6)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '증상 종료',
                      style: AppTextStyle.body.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.background,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.hp(2)),
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline(
    BuildContext context,
    List<Map<String, dynamic>> sortedHistories,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sortedHistories.length,
      itemBuilder: (context, index) {
        final history = sortedHistories[index];
        final historyDate = DateTime.parse(history['record_date']).toLocal();
        final currentDate = TimeFormat.getDate(history['record_date']);
        // final currentDate = _formatDateOnly(historyDate);
        final previousDate =
            index > 0
                ? TimeFormat.getDate(
                  sortedHistories[index - 1]['record_date'],
                ) // 이전 인덱스의 날짜
                : '';
        // 해당 history에 연결된 이미지들 찾기
        final historyImages =
            widget.images
                .where((img) => img['history_id'] == history['history_id'])
                .toList();

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.25,
          isFirst: index == 0,
          isLast: index == sortedHistories.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 12,
            height: 12,
            color: Colors.blueAccent,
          ),
          beforeLineStyle: LineStyle(
            color: AppColors.backgroundSecondary,
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: AppColors.backgroundSecondary,
            thickness: 2,
          ),
          startChild:
              currentDate != previousDate
                  ? Padding(
                    padding: EdgeInsets.only(right: context.wp(4)),
                    child: Text(
                      currentDate,
                      style: AppTextStyle.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  )
                  : null,
          endChild: Container(
            padding: EdgeInsets.only(left: 12, bottom: 16, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 이벤트 타입 및 정보
                      Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _getEventTypeLabel(history),
                            style: AppTextStyle.subTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            _formatTimeOnly(historyDate),
                            style: AppTextStyle.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      // 치료
                      if (history['treatment_name'] != null &&
                          history['treatment_name']
                              .toString()
                              .trim()
                              .isNotEmpty) ...[
                        Text(
                          '${history['treatment_name']} 치료',
                          style: AppTextStyle.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],

                      // 메모
                      if (history['memo'] != null &&
                          history['memo'].toString().trim().isNotEmpty) ...[
                        Text(
                          history['memo'],
                          style: AppTextStyle.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                        ),
                      ],

                      // 이미지 썸네일
                      if (historyImages.isNotEmpty) ...[
                        // SizedBox(height: context.hp(1)),
                        SizedBox(
                          height: 60,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: BouncingScrollPhysics(),
                            child: Container(
                              width: (historyImages.length * 35.0) + 25,
                              child: Stack(
                                children: List.generate(historyImages.length, (
                                  imgIndex,
                                ) {
                                  final imagePath =
                                      historyImages[imgIndex]['image_url']
                                          as String;
                                  final double angle = ((imgIndex -
                                              (historyImages.length - 1) / 2) *
                                          0.05)
                                      .clamp(-0.08, 0.08);
                                  final double leftPosition =
                                      imgIndex * 35.0; // 사진 간의 간격

                                  return Positioned(
                                    left: leftPosition,
                                    child: Transform.rotate(
                                      angle: angle,
                                      child: GestureDetector(
                                        onTap:
                                            () => widget.onImageTap(
                                              widget.images,
                                              widget.images.indexOf(
                                                historyImages[imgIndex],
                                              ),
                                            ),
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          margin: EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: AppColors.background,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                            child: Image.file(
                                              File(imagePath),
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  color: AppColors.lightGrey,
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 20,
                                                    color: AppColors.lightGrey,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_showActions)
                  Row(
                    spacing: 12,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.black,
                        ),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.black,
                        ),
                        child: Icon(
                          LucideIcons.edit,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeOnly(DateTime date) {
    return '${date.hour}시 ${date.minute}분';
  }

  String _getEventTypeLabel(Map<String, dynamic> history) {
    final eventType = history['event_type'];

    switch (eventType) {
      case 'INITIAL':
        return '증상 시작';
      case 'PROGRESS':
        return '진행 경과';
      case 'TREATMENT':
        return '치료';
      case 'COMPLETE':
        return '증상 종료';
      default:
        return eventType ?? '기록';
    }
  }
}
