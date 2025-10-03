import 'dart:io';
import 'dart:math' as math;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordFormImageWidget extends StatefulWidget {
  final List<String>? initialImagePaths;

  const RecordFormImageWidget({super.key, this.initialImagePaths});

  @override
  State<RecordFormImageWidget> createState() => RecordFormImageWidgetState();
}

class RecordFormImageWidgetState extends State<RecordFormImageWidget> {
  List<String> _allImagePaths = [];
  bool _isPickingImages = false;
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _updateImagePaths();
  }

  @override
  void didUpdateWidget(RecordFormImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImagePaths != widget.initialImagePaths) {
      _updateImagePaths();
    }
  }

  void _updateImagePaths() {
    if (mounted) {
      setState(() {
        _allImagePaths = List.from(widget.initialImagePaths ?? []);
      });
    }
  }

  List<String> getSelectedImagePaths() {
    return _allImagePaths;
  }

  Future<void> _pickImages() async {
    if (_isPickingImages || !mounted) return;

    setState(() {
      _isPickingImages = true;
    });

    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        setState(() {
          _allImagePaths.addAll(images.map((image) => image.path));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImages = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _allImagePaths.length && mounted) {
      setState(() {
        _allImagePaths.removeAt(index);
        if (_currentIndex >= _allImagePaths.length &&
            _allImagePaths.isNotEmpty) {
          _currentIndex = _allImagePaths.length - 1;
        }
      });
    }
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _pickImages();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(LucideIcons.image, size: 16, color: AppColors.textSecondary),
            Text(
              '사진 추가',
              style: AppTextStyle.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _pickImages();
          },
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              color: AppColors.background,
            ),
            child: Row(
              children: [
                Text(
                  '사진 추가',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),

        if (_allImagePaths.isNotEmpty)
          CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height: context.wp(90),
              aspectRatio: 1.0,
              enableInfiniteScroll: false,
              viewportFraction: 1,
              onPageChanged: (index, reason) {
                if (mounted) {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
            ),
            items:
                _allImagePaths.map((imagePath) {
                  return Stack(
                    children: [
                      ClipRRect(
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: context.wp(90),
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.lightGrey.withValues(alpha: 0.3),
                              child: Center(
                                child: Icon(
                                  LucideIcons.imageOff,
                                  size: 48,
                                  color: AppColors.lightGrey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _pickImages();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.black.withValues(
                                      alpha: 0.7,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.plus,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  final imageIndex = _allImagePaths.indexOf(
                                    imagePath,
                                  );
                                  if (imageIndex != -1) {
                                    _removeImage(imageIndex);
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.black.withValues(
                                      alpha: 0.7,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.trash2,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_allImagePaths.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / ${_allImagePaths.length}',
                                style: AppTextStyle.body.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
          ),
        if (_allImagePaths.length > 1) ...[
          SizedBox(height: context.hp(1)),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _allImagePaths.length,
              itemBuilder: (context, index) {
                final imagePath = _allImagePaths[index];
                final isSelected = index == _currentIndex;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (mounted) {
                      setState(() {
                        _currentIndex = index;
                      });
                    }
                    _carouselController.jumpToPage(index);
                  },
                  child: Container(
                    width: 45,
                    height: 45,
                    margin: EdgeInsets.only(right: context.wp(1)),
                    child: ClipRRect(
                      child: Stack(
                        children: [
                          Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width: 45,
                            height: 45,
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
                                alpha: 0.7,
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
      ],
    );
  }
}
