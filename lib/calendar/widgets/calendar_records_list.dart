import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarRecordsList extends StatelessWidget {
  final List<Map<String, dynamic>> dayRecords;
  final bool isLoading;
  final Function(Map<String, dynamic>) onRecordTap;
  final Function(double) onHeightChanged;

  const CalendarRecordsList({
    Key? key,
    required this.dayRecords,
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
                        Padding(
                          padding: EdgeInsets.all(context.wp(4)),
                          child: GestureDetector(
                            onTap: () {
                              // TODOLIST 레코드 페이지 이동, onDataChanged 콜백함수 호출
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                '증상 기록하기',
                                style: AppTextStyle.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
                      return _buildRecordItem(record);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final color = Color(int.parse(record['color']));
    final localDate = DateTime.parse(record['start_date']);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService().getImages(record['record_id']),
      builder: (context, snapshot) {
        final images = snapshot.data ?? [];

        return GestureDetector(
          onTap: () => onRecordTap(record),
          child: Container(
            margin: EdgeInsets.only(
              top: context.hp(0.5),
              bottom: context.hp(2),
            ),
            padding: context.paddingSM,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
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
                            width: 8,
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
                                style: AppTextStyle.subTitle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                record['spot_name'] ?? '부위 없음',
                                style: AppTextStyle.body.copyWith(
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
                    Text(
                      '${localDate.hour < 12 ? 'AM' : 'PM'} ${localDate.hour % 12 == 0 ? 12 : localDate.hour % 12}:${localDate.minute.toString().padLeft(2, '0')}',
                      style: AppTextStyle.body.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                if (record['memo'] != null &&
                    record['memo'].toString().trim().isNotEmpty)
                  Padding(
                    padding: context.paddingXS,
                    child: Text(
                      record['memo'],
                      style: AppTextStyle.caption.copyWith(
                        color: AppColors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
      },
    );
  }

  Widget _buildImageStack(List<Map<String, dynamic>> images) {
    final displayCount = images.length > 5 ? 5 : images.length;
    final remainingCount = images.length - displayCount;

    return SizedBox(
      height: 50,
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
}
