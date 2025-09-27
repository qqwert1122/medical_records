import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:medical_records/services/database_service.dart';

class RecentRecordsSection extends StatefulWidget {
  final List<Map<String, dynamic>> recentRecords;
  final VoidCallback onMorePressed;

  const RecentRecordsSection({
    super.key,
    required this.recentRecords,
    required this.onMorePressed,
  });

  @override
  State<RecentRecordsSection> createState() => _RecentRecordsSectionState();
}

class _RecentRecordsSectionState extends State<RecentRecordsSection> {
  Map<int, List<Map<String, dynamic>>> _recordImages = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didUpdateWidget(RecentRecordsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recentRecords != oldWidget.recentRecords) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    final Map<int, List<Map<String, dynamic>>> images = {};

    for (final record in widget.recentRecords) {
      final recordId = record['record_id'];
      try {
        // 해당 record의 모든 history 조회
        final histories = await DatabaseService().getHistories(recordId);

        // 각 history의 이미지들을 수집
        List<Map<String, dynamic>> allImages = [];
        for (final history in histories) {
          final historyId = history['history_id'];
          final historyImages = await DatabaseService().getImages(historyId);
          allImages.addAll(historyImages);
        }

        images[recordId] = allImages;
      } catch (e) {
        images[recordId] = [];
      }
    }

    if (mounted) {
      setState(() {
        _recordImages = images;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 기록',
                style: AppTextStyle.subTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: widget.onMorePressed,
                child: Text(
                  '더 보기',
                  style: AppTextStyle.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          widget.recentRecords.isEmpty
              ? Container(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '최근 기록이 없습니다',
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
              : Column(
                children:
                    widget.recentRecords.map((record) {
                      return _buildRecentRecordItem(record);
                    }).toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordItem(Map<String, dynamic> record) {
    final String startDate = record['start_date'];
    final String? endDate = record['end_date'];
    final color = Color(int.parse(record['color']));
    final bool isComplete = record['end_date'] != null;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 색깔 바, 증상 이름, 부위 이름, 뱃지
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 40,
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 10,
                    children: [
                      Text(
                        record['symptom_name'],
                        style: AppTextStyle.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isComplete
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        record['spot_name'] ?? '부위 없음',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      endDate != null
                          ? _buildTimeRow('종료', TimeFormat.getDate(endDate))
                          : _buildTimeRow('시작', TimeFormat.getDate(startDate)),
                      _buildStatusBadge(record),
                    ],
                  ),
                ],
              ),
            ],
          ),
          _buildImageStack(_recordImages[record['record_id']] ?? []),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> record) {
    final endDate = record['end_date'];

    String status;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (endDate != null) {
      status = '종료';
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
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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

  Widget _buildTimeRow(String label, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4),
        Text(
          time,
          style: AppTextStyle.caption.copyWith(color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildImageStack(List<Map<String, dynamic>> images) {
    final displayCount = images.length > 3 ? 3 : images.length;
    final remainingCount = images.length - displayCount;

    const double tileSize = 50.0;
    const double step = 40.0;
    double stackWidth = tileSize + (displayCount - 1) * step;

    if (images.isEmpty) {
      return SizedBox(width: tileSize, height: tileSize);
    }

    return SizedBox(
      height: tileSize,
      width: stackWidth,
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            final image = images[index];

            return Positioned(
              left: index * step,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.background, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image['image_url']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.lightGrey,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 20,
                          color: AppColors.lightGrey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textPrimary,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
