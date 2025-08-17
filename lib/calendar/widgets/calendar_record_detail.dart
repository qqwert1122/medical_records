import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';

class CalendarRecordDetail extends StatefulWidget {
  final Map<String, dynamic> record;
  final VoidCallback onBackPressed;

  const CalendarRecordDetail({
    super.key,
    required this.record,
    required this.onBackPressed,
  });

  @override
  State<CalendarRecordDetail> createState() => _CalendarRecordDetailState();
}

class _CalendarRecordDetailState extends State<CalendarRecordDetail> {
  List<Map<String, dynamic>> _recordImages = [];
  bool _isLoadingImages = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRecordImages();
  }

  @override
  void didUpdateWidget(CalendarRecordDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.record['record_id'] != oldWidget.record['record_id'] ||
        widget.record['updated_at'] != oldWidget.record['updated_at']) {
      _loadRecordImages();
    }
  }

  Future<void> _loadRecordImages() async {
    setState(() => _isLoadingImages = true);

    try {
      // 1. record_id로 모든 history 가져오기
      final histories = await DatabaseService().getHistories(
        widget.record['record_id'],
      );

      // 2. 모든 history의 이미지 수집
      List<Map<String, dynamic>> allImages = [];
      for (final history in histories) {
        final historyImages = await DatabaseService().getImages(
          history['history_id'],
        );
        allImages.addAll(historyImages);
      }

      // 3. 중복 제거 (필요한 경우)
      final uniqueImages = allImages.toSet().toList();

      if (mounted) {
        setState(() {
          _recordImages = uniqueImages;
          _isLoadingImages = false;
          _currentImageIndex = 0;
        });
      }
    } catch (e) {
      print('이미지 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoadingImages = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localStartDate =
        DateTime.parse(widget.record['start_date']).toLocal();
    final localCreateDate =
        DateTime.parse(widget.record['created_at']).toLocal();
    final localUpdateDate =
        DateTime.parse(widget.record['updated_at']).toLocal();

    return Column(
      children: [
        // 컨텐츠
        Expanded(
          child: SingleChildScrollView(
            padding: context.paddingSM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 갤러리
                if (_isLoadingImages) ...[
                  SizedBox(
                    height: context.hp(50),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.black),
                    ),
                  ),
                ] else if (_recordImages.isNotEmpty) ...[
                  _buildImageGallery(),
                ],

                // 메모
                if (widget.record['memo'] != null &&
                    widget.record['memo'].toString().trim().isNotEmpty) ...[
                  SizedBox(height: context.hp(2)),
                  Container(
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
                          '메모',
                          style: AppTextStyle.subTitle.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        SizedBox(height: context.hp(1)),
                        Text(widget.record['memo'], style: AppTextStyle.body),
                      ],
                    ),
                  ),
                ],

                // 상세 정보
                SizedBox(height: context.hp(2)),
                Container(
                  padding: context.paddingSM,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: LucideIcons.palette,
                        label: '색깔',
                        color: widget.record['color'],
                      ),
                      _buildInfoRow(
                        icon: LucideIcons.mapPin,
                        label: '부위',
                        value: widget.record['spot_name'],
                      ),
                      _buildInfoRow(
                        icon: LucideIcons.calendar,
                        label: '기록 날짜',
                        value: _formatDateTime(localStartDate),
                      ),
                      if (widget.record['end_date'] != null)
                        _buildInfoRow(
                          icon: Icons.event_available,
                          label: '종료 날짜',
                          value: _formatDateTime(
                            DateTime.parse(widget.record['end_date']).toLocal(),
                          ),
                        ),
                      _buildInfoRow(
                        icon: LucideIcons.calendar,
                        label: '생성일',
                        value: _formatDateTime(localCreateDate),
                      ),
                      _buildInfoRow(
                        icon: LucideIcons.hash,
                        label: 'No',
                        value: '${widget.record['record_id']}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    String? color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(0.8)),
      child: Row(
        children: [
          Icon(icon, size: context.lg, color: AppColors.grey),
          SizedBox(width: context.wp(4)),
          Text(label, style: AppTextStyle.body.copyWith(color: AppColors.grey)),
          const Spacer(),
          if (value != null) Text(value, style: AppTextStyle.body),
          if (color != null)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Color(int.parse(color)),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'PROGRESS':
        return '진행중';
      case 'TREATMENT':
        return '치료중';
      case 'COMPLETE':
        return '완료';
      default:
        return status ?? '-';
    }
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: context.hp(50),
          child: CarouselSlider(
            options: CarouselOptions(
              height: context.hp(50),
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              viewportFraction: 0.8,
              enlargeFactor: 0.3,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
            ),
            items:
                _recordImages.map((image) {
                  final imagePath = image['image_url'] as String;
                  return GestureDetector(
                    onTap:
                        () => _showFullScreenImage(
                          _recordImages,
                          _recordImages.indexOf(image),
                        ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_recordImages.length > 1)
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentImageIndex + 1}/${_recordImages.length}',
                                    style: AppTextStyle.caption.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(
    List<Map<String, dynamic>> images,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FullScreenImageGallery(
              images: images,
              initialIndex: initialIndex,
            ),
      ),
    );
  }
}

// 전체화면 이미지 갤러리
class FullScreenImageGallery extends StatelessWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final imagePath = images[index]['image_url'] as String;
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(imagePath)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
              );
            },
            itemCount: images.length,
            loadingBuilder:
                (context, event) => Center(
                  child: CircularProgressIndicator(
                    value:
                        event == null
                            ? 0
                            : event.cumulativeBytesLoaded /
                                (event.expectedTotalBytes ?? 1),
                    color: Colors.white,
                  ),
                ),
            pageController: PageController(initialPage: initialIndex),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${initialIndex + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
