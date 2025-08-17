import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medical_records/calendar/widgets/record_memos.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:path/path.dart';

class CalendarRecordsList extends StatelessWidget {
  final List<Map<String, dynamic>> dayRecords;
  final Map<int, List<Map<String, dynamic>>> recordImages;
  final Map<int, List<String>> recordMemos;
  final bool isLoading;
  final Function(Map<String, dynamic>) onRecordTap;
  final Function(double) onHeightChanged;

  const CalendarRecordsList({
    Key? key,
    required this.dayRecords,
    required this.recordImages,
    required this.recordMemos,
    required this.isLoading,
    required this.onRecordTap,
    required this.onHeightChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.hp(1)),
        Expanded(
          child:
              isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  )
                  : dayRecords.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/empty_box.png',
                          width: context.wp(30),
                          height: context.wp(30),
                          color: AppColors.grey,
                        ),
                        Text(
                          '기록된 증상이 없어요',
                          style: AppTextStyle.body.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: context.paddingHorizSM,
                    itemCount: dayRecords.length,
                    itemBuilder: (context, index) {
                      final record = dayRecords[index];
                      return _buildRecordItem(context, record);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildRecordItem(BuildContext context, Map<String, dynamic> record) {
    final recordId = record['record_id'];
    final color = Color(int.parse(record['color']));
    final DateTime startDate = DateTime.parse(record['start_date']);
    final DateTime? endDate =
        (record['end_date'] != null &&
                record['end_date'].toString().trim().isNotEmpty)
            ? DateTime.parse(record['end_date'])
            : null;

    final images = recordImages[recordId] ?? [];
    final memos = recordMemos[recordId] ?? [];

    return GestureDetector(
      onTap: () => onRecordTap(record),
      child: Container(
        margin: EdgeInsets.only(bottom: context.hp(1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      SizedBox(width: context.wp(4)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record['symptom_name'] ?? '증상 없음',
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            record['spot_name'] ?? '부위 없음',
                            style: AppTextStyle.caption.copyWith(
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: context.paddingXS,
                  child: _buildTimeRange(startDate, endDate),
                ),
              ],
            ),
            if (memos.isNotEmpty) RecordMemo(memos: memos),

            if (images.isNotEmpty) ...[
              Padding(
                padding: context.paddingXS,
                child: _buildImageStack(images),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageStack(List<Map<String, dynamic>> images) {
    final displayCount = images.length > 3 ? 3 : images.length;
    final remainingCount = images.length - displayCount;

    const double tileSize = 50.0;
    const double step = 40.0;
    double stackWidth = tileSize + (displayCount - 1) * step;
    if (remainingCount > 0) {
      stackWidth = tileSize + displayCount * step;
    }

    return SizedBox(
      height: tileSize,
      width: stackWidth,
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            final image = images[index];

            return Positioned(
              left: index * 40.0,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 20,
                          color: Colors.grey[500],
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
              left: displayCount * 40.0,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRange(DateTime start, DateTime? end) {
    final startDate = TimeFormat.formatAmPm(start);
    final endDate = end != null ? TimeFormat.formatAmPm(end) : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              '시작일',
              style: AppTextStyle.caption.copyWith(color: AppColors.grey),
            ),
            Text(
              startDate,
              style: AppTextStyle.caption.copyWith(color: AppColors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              '종료일',
              style: AppTextStyle.caption.copyWith(color: AppColors.grey),
            ),
            Text(
              endDate,
              style: AppTextStyle.caption.copyWith(color: AppColors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
