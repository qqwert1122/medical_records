import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/records/screens/record_foam_page.dart';
import 'package:medical_records/services/analysis_service.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'dart:io';

class Record extends StatefulWidget {
  final Map<String, dynamic> recordData;
  final VoidCallback? onRecordUpdated;

  const Record({super.key, required this.recordData, this.onRecordUpdated});

  @override
  State<Record> createState() => _RecordState();
}

class _RecordState extends State<Record> {
  bool isCompleted = false;
  List<String> imagePaths = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 완료 상태 확인
    final hasComplete = await AnalysisService().hasCompleteStatus(
      widget.recordData['history_id'].toString(),
    );

    // 이미지들 가져오기
    final images = await DatabaseService().getImages(
      widget.recordData['record_id'],
    );

    setState(() {
      isCompleted = hasComplete;
      imagePaths = images.map((img) => img['image_url'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.recordData;
    final date = DateTime.parse(record['date']);
    final now = DateTime.now();
    final formattedDate =
        date.year == now.year
            ? '${date.month}월 ${date.day}일'
            : '${date.year}년 ${date.month}월 ${date.day}일';

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecordFoamPage(recordData: record),
          ),
        );
        widget.onRecordUpdated?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        padding: context.paddingXS,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Color(int.parse(record['color'])),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/mouth_nobg.png',
                                width: 45,
                                height: 45,
                              ),
                            ),
                          ),
                          SizedBox(width: context.wp(2)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: AppTextStyle.caption.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        record['symptom_name'] ?? '',
                                        style: AppTextStyle.body.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: context.wp(0.5)),
                                    Text(
                                      '|',
                                      style: AppTextStyle.caption.copyWith(
                                        color: AppColors.grey,
                                      ),
                                    ),
                                    SizedBox(width: context.wp(0.5)),
                                    Flexible(
                                      child: Text(
                                        record['spot_name'] ?? '기록',
                                        style: AppTextStyle.body.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: context.wp(1)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isCompleted
                                                ? AppColors.grey
                                                : Colors.blueAccent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isCompleted ? '완료' : '진행중',
                                        style: AppTextStyle.caption.copyWith(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [],
                      ),
                    ],
                  ),
                ),
                if (imagePaths.isNotEmpty) _buildImageStack(),
              ],
            ),
            SizedBox(height: context.hp(1)),
            record['memo'] == ''
                ? SizedBox()
                : Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    record['memo'],
                    style: AppTextStyle.caption.copyWith(),
                  ),
                ),
            SizedBox(height: context.hp(2)),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageStack() {
    const double imageSize = 50;
    const double overlap = 30;

    return SizedBox(
      width:
          imagePaths.length == 1
              ? imageSize
              : imageSize +
                  (imagePaths.length.clamp(0, 3) - 1) * (imageSize - overlap) +
                  10,
      // (imagePaths.length > 3 ? 10 : 0), // +n 뱃지 공간
      height: imageSize + 12,
      child: Stack(
        children: [
          // 이미지들 (최대 3개까지만 표시)
          ...imagePaths.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final imagePath = entry.value;

            // 회전 각도 계산 (왼쪽은 음수, 오른쪽은 양수)
            double rotation = 0;
            if (imagePaths.length == 2) {
              // 2장일 경우: 좌우 대칭
              rotation = index == 0 ? -0.15 : 0.15;
            } else if (imagePaths.length > 2) {
              // 3장 이상일 경우: 왼쪽은 음수, 오른쪽은 양수
              rotation = (index - 1) * 0.2; // -0.2, 0, 0.2 라디안
            }

            return Positioned(
              top: imagePaths.length == 2 ? 0 : (index == 1 ? 0 : 10),
              left: index * (imageSize - overlap),
              child: Transform.rotate(
                angle: rotation,
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child:
                        File(imagePath).existsSync()
                            ? Image.file(File(imagePath), fit: BoxFit.cover)
                            : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                ),
              ),
            );
          }).toList(),

          // +n 뱃지 (3장 초과시)
          if (imagePaths.length > 3)
            Positioned(
              left: 3 * (imageSize - overlap),
              bottom: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+${imagePaths.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // 경과 기록 로직
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '경과 기록',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        SizedBox(width: context.wp(2)),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // 종료 로직
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '종료',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
