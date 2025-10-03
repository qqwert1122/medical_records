import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';

class RecordDetailImageWidget extends StatefulWidget {
  final List<Map<String, dynamic>> histories;
  final List<Map<String, dynamic>> images;
  final Function(List<Map<String, dynamic>>, int) onImageTap;

  const RecordDetailImageWidget({
    super.key,
    required this.histories,
    required this.images,
    required this.onImageTap,
  });

  @override
  State<RecordDetailImageWidget> createState() =>
      _RecordDetailImageWidgetState();
}

class _RecordDetailImageWidgetState extends State<RecordDetailImageWidget> {
  int _currentImageIndex = 0;
  late CarouselSliderController _carouselController =
      CarouselSliderController();
  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 1;

    return Container(
      decoration: BoxDecoration(color: AppColors.background),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.hp(1)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '사진',
                style: AppTextStyle.subTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height: imageSize,
              aspectRatio: 1.0,
              enableInfiniteScroll: false,
              viewportFraction: 1,
              onPageChanged: (index, reason) {
                if (mounted) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                }
              },
            ),
            items:
                widget.images.map((image) {
                  final imagePath = image['image_url'] as String;
                  final history = widget.histories.firstWhere(
                    (history) => history['history_id'] == image['history_id'],
                    orElse: () => {},
                  );

                  final historyMemo = history['memo'] ?? '';
                  final eventType = history['event_type'] ?? '';
                  final eventName = switch (eventType) {
                    'INITIAL' => '증상 시작',
                    'COMPLETE' => '증상 종료',
                    'PROGRESS' => '경과 기록',
                    'TREATMENT' => '치료 기록',
                    _ => eventType,
                  };
                  final treatmentName = history['treatment_name'] ?? '';
                  final recordDate = history['record_date'] ?? '';

                  return GestureDetector(
                    onTap:
                        () => widget.onImageTap(
                          widget.images,
                          widget.images.indexOf(image),
                        ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                child: Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: imageSize,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.lightGrey,
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: AppColors.lightGrey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (eventType.isNotEmpty)
                                        Text(
                                          eventName,
                                          style: AppTextStyle.caption.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (treatmentName.isNotEmpty)
                                        Text(
                                          treatmentName,
                                          style: AppTextStyle.caption.copyWith(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      if (recordDate.isNotEmpty)
                                        Text(
                                          TimeFormat.getDate(recordDate),
                                          style: AppTextStyle.caption.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        historyMemo.toString().trim().isEmpty
                            ? SizedBox()
                            : Container(
                              width: double.infinity,
                              padding: context.paddingSM,
                              decoration: BoxDecoration(
                                color: AppColors.background,

                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.backgroundSecondary,
                                    width: widget.images.length > 1 ? 0.5 : 0,
                                  ),
                                ),
                              ),
                              child: Text(
                                historyMemo,
                                style: AppTextStyle.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                      ],
                    ),
                  );
                }).toList(),
          ),
          if (widget.images.length > 1) ...[
            SizedBox(height: context.hp(1)),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
                itemBuilder: (context, index) {
                  final imagePath = widget.images[index]['image_url'] as String;
                  final isSelected = index == _currentImageIndex;

                  return GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      }
                      _carouselController.jumpToPage(index);
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      padding: EdgeInsets.only(right: context.wp(1)),
                      child: ClipRRect(
                        child: Stack(
                          children: [
                            Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.lightGrey,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 24,
                                    color: AppColors.backgroundSecondary,
                                  ),
                                );
                              },
                            ),
                            if (!isSelected)
                              Container(
                                color: AppColors.textPrimary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: context.hp(2)),
        ],
      ),
    );
  }
}
