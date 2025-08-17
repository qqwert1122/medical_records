import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/calendar/widgets/record_time_line.dart';
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
  final List<Map<String, dynamic>> histories;
  final List<Map<String, dynamic>> images;
  final List<String> memos;
  final VoidCallback onBackPressed;

  const CalendarRecordDetail({
    super.key,
    required this.record,
    required this.histories,
    required this.images,
    required this.memos,
    required this.onBackPressed,
  });

  @override
  State<CalendarRecordDetail> createState() => _CalendarRecordDetailState();
}

class _CalendarRecordDetailState extends State<CalendarRecordDetail> {
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final localStartDate =
        DateTime.parse(widget.record['start_date']).toLocal();
    final localCreateDate =
        DateTime.parse(widget.record['created_at']).toLocal();

    return Column(
      children: [
        // 컨텐츠
        Expanded(
          child: SingleChildScrollView(
            padding: context.paddingHorizSM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 갤러리
                if (widget.images.isNotEmpty) ...[_buildImageGallery()],

                // 메모
                if (widget.memos.isNotEmpty) ...[
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
                        ...widget.memos
                            .map(
                              (memo) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: context.hp(0.5),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('• ', style: AppTextStyle.body),
                                    Expanded(
                                      child: Text(
                                        memo,
                                        style: AppTextStyle.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ],

                // 타임라인
                if (widget.histories.isNotEmpty) ...[
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
                          '기록 타임라인',
                          style: AppTextStyle.subTitle.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        SizedBox(height: context.hp(1)),
                        ...widget.histories.map((history) {
                          final historyDate =
                              DateTime.parse(history['created_at']).toLocal();
                          return Padding(
                            padding: EdgeInsets.only(bottom: context.hp(1)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: context.wp(2)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDateTime(historyDate),
                                        style: AppTextStyle.caption.copyWith(
                                          color: AppColors.grey,
                                        ),
                                      ),
                                      if (history['memo'] != null &&
                                          history['memo']
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                        Text(
                                          history['memo'],
                                          style: AppTextStyle.body,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],

                // 타임라인
                RecordTimeline(
                  record: widget.record,
                  histories: widget.histories,
                  images: widget.images,
                  onImageTap: _showFullScreenImage,
                ),

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
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: imageSize,
            aspectRatio: 1.0,
            enableInfiniteScroll: false,
            viewportFraction: 1,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items:
              widget.images.map((image) {
                final imagePath = image['image_url'] as String;
                final historyMemo =
                    widget.histories.firstWhere(
                      (history) => history['history_id'] == image['history_id'],
                      orElse: () => {'memo': ''},
                    )['memo'] ??
                    '';

                return GestureDetector(
                  onTap:
                      () => _showFullScreenImage(
                        widget.images,
                        widget.images.indexOf(image),
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: imageSize,
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
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.grey.withValues(alpha: 0.5),

                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              historyMemo.toString().trim().isEmpty
                                  ? ' '
                                  : historyMemo,
                              style: AppTextStyle.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    setState(() {
                      _currentImageIndex = index;
                    });
                    _carouselController.jumpToPage(index);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: EdgeInsets.only(right: context.wp(2)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: AppColors.surface, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
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
                          if (!isSelected)
                            Container(
                              color: Colors.black.withValues(alpha: 0.3),
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
class FullScreenImageGallery extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final imagePath = widget.images[index]['image_url'] as String;
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(imagePath)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
              );
            },
            itemCount: widget.images.length,
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
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
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
                  if (widget.images.length > 1)
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
                        '${_currentIndex + 1} / ${widget.images.length}',
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
