import 'dart:io';
import 'dart:math' as math;

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordFoamImageWidget extends StatefulWidget {
  final List<String>? initialImagePaths;

  const RecordFoamImageWidget({super.key, this.initialImagePaths});

  @override
  State<RecordFoamImageWidget> createState() => RecordFoamImageWidgetState();
}

class RecordFoamImageWidgetState extends State<RecordFoamImageWidget>
    with SingleTickerProviderStateMixin {
  List<String> _allImagePaths = [];
  bool _isPickingImages = false;
  final CardSwiperController _swiperController = CardSwiperController();
  int _currentIndex = 0;
  late AnimationController _tiltController;
  final math.Random _random = math.Random();

  // 각 카드의 랜덤 틸트 각도를 저장
  final Map<int, double> _tiltAngles = {};

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _updateImagePaths();
  }

  @override
  void dispose() {
    _tiltController.dispose();
    _swiperController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RecordFoamImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImagePaths != widget.initialImagePaths) {
      _updateImagePaths();
    }
  }

  void _updateImagePaths() {
    setState(() {
      _allImagePaths = List.from(widget.initialImagePaths ?? []);
      // 각 이미지에 대한 랜덤 틸트 각도 생성 (-5도 ~ 5도)
      for (int i = 0; i < _allImagePaths.length; i++) {
        _tiltAngles[i] = (_random.nextDouble() - 0.5) * 10 * (math.pi / 180);
      }
    });
  }

  List<String> getSelectedImagePaths() {
    return _allImagePaths;
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return;

    setState(() {
      _isPickingImages = true;
    });

    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          final startIndex = _allImagePaths.length;
          _allImagePaths.addAll(images.map((image) => image.path));
          // 새로 추가된 이미지들에 대한 틸트 각도 생성
          for (int i = startIndex; i < _allImagePaths.length; i++) {
            _tiltAngles[i] =
                (_random.nextDouble() - 0.5) * 10 * (math.pi / 180);
          }
        });
      }
    } finally {
      setState(() {
        _isPickingImages = false;
      });
    }
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _allImagePaths.length) {
      // 현재 표시 중인 인덱스 저장
      final currentActualIndex = _currentIndex % _allImagePaths.length;

      setState(() {
        _allImagePaths.removeAt(index);
        // 틸트 각도 맵 재구성
        _tiltAngles.clear();
        for (int i = 0; i < _allImagePaths.length; i++) {
          _tiltAngles[i] = (_random.nextDouble() - 0.5) * 10 * (math.pi / 180);
        }

        // 삭제 후 인덱스 조정
        if (_allImagePaths.isNotEmpty) {
          if (index <= currentActualIndex) {
            _currentIndex = math.max(0, _currentIndex - 1);
          }
        } else {
          _currentIndex = 0;
        }
      });
    }
  }

  Widget _buildImageCard(String imagePath, int index) {
    // 카드별 랜덤 틸트 각도 적용
    final tiltAngle = _tiltAngles[index] ?? 0.0;

    return Transform.rotate(
      angle: tiltAngle,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 이미지
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
              //
              // 삭제 버튼
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // 실제 이미지 경로의 인덱스를 찾아서 삭제
                      final imageIndex = _allImagePaths.indexOf(imagePath);
                      if (imageIndex != -1) {
                        _removeImage(imageIndex);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              // 추가 버튼
              Positioned(
                bottom: 12,
                right: 12,
                child: Material(
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
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              // 페이지 인디케이터
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${(_currentIndex % _allImagePaths.length) + 1} / ${_allImagePaths.length}',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Transform.rotate(
        angle: 0,
        // (_random.nextDouble() - 0.5) * 6 * (math.pi / 180), // 빈 상태도 살짝 틸트
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            color: AppColors.grey,
            strokeWidth: 1,
            dashPattern: [8, 4],
            radius: Radius.circular(20),
          ),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _pickImages();
            },
            child: Container(
              width: context.wp(80),
              decoration: BoxDecoration(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.image,
                    size: 56,
                    color: AppColors.grey.withValues(alpha: 0.6),
                  ),
                  SizedBox(height: context.hp(3)),
                  Text(
                    '사진을 추가해주세요',
                    style: AppTextStyle.subTitle.copyWith(
                      color: AppColors.grey.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.hp(1)),
                  Text(
                    '여기를 탭하여 갤러리에서 선택',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카드 스와이퍼
        Container(
          height: context.hp(40),
          child:
              _allImagePaths.isEmpty
                  ? _buildEmptyState()
                  : CardSwiper(
                    key: ValueKey(_allImagePaths.length),
                    controller: _swiperController,
                    cardsCount: _allImagePaths.length,
                    numberOfCardsDisplayed: math.min(_allImagePaths.length, 3),
                    backCardOffset: const Offset(35, 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    cardBuilder: (
                      BuildContext context,
                      int index,
                      int percentThresholdX,
                      int percentThresholdY,
                    ) {
                      // 인덱스 범위 체크
                      if (index >= _allImagePaths.length) {
                        return Container(); // 빈 컨테이너 반환
                      }
                      return _buildImageCard(_allImagePaths[index], index);
                    },
                    isLoop: true, // 무한 루프 활성화
                    allowedSwipeDirection: AllowedSwipeDirection.symmetric(
                      horizontal: true,
                      vertical: true, // 상하좌우 모두 가능
                    ),
                    onSwipe: (previousIndex, currentIndex, direction) {
                      setState(() {
                        _currentIndex = currentIndex ?? 0;
                      });

                      // 스와이프 방향에 따른 다른 햅틱
                      if (direction == CardSwiperDirection.left ||
                          direction == CardSwiperDirection.right) {
                        HapticFeedback.lightImpact();
                      } else {
                        HapticFeedback.selectionClick();
                      }

                      return true;
                    },
                    scale: 0.85, // 뒤쪽 카드 크기 비율
                    threshold: 40, // 스와이프 감도
                  ),
        ),
      ],
    );
  }
}
