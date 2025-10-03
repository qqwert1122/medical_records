import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/services/pref_service.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/features/form/screens/record_form_page.dart';

class HeadDetailPage extends StatefulWidget {
  final bool? initialIsMale;

  const HeadDetailPage({super.key, this.initialIsMale});

  @override
  State<HeadDetailPage> createState() => _HeadDetailPageState();
}

class _HeadDetailPageState extends State<HeadDetailPage> {
  Offset? markedPoint;
  String? detectedBodyPart;
  late bool isMale;
  final PrefService _prefService = PrefService();

  @override
  void initState() {
    super.initState();
    // initialIsMale이 있으면 바로 사용, 없으면 기본값 true
    isMale = widget.initialIsMale ?? true;
    _loadGenderPreference();
  }

  Future<void> _loadGenderPreference() async {
    // initialIsMale이 전달되지 않은 경우에만 저장된 값 로드
    if (widget.initialIsMale == null) {
      await _prefService.init();
      if (mounted) {
        setState(() {
          isMale = _prefService.getGenderIsMale();
        });
      }
    }
  }

  Future<void> _saveGenderPreference(bool isMale) async {
    await _prefService.setGenderIsMale(isMale);
  }

  String? _detectBodyPart(double x, double y) {
    // 512x512 이미지 기준 좌표

    if (isMale) {
      // 이마 (상단)
      if (y >= 100 && y <= 210) {
        return '이마';
      }

      // 눈 영역
      if (y >= 210 && y <= 280) {
        if (x >= 150 && x <= 215) return '눈';
        if (x >= 290 && x <= 360) return '눈';
      }

      // 귀 영역 (좌우 끝)
      if (y >= 180 && y <= 330) {
        if (x <= 100 || x >= 412) {
          return '귀';
        }
      }

      // 코 영역 (중앙)
      if (y >= 210 && y <= 315 && x >= 215 && x <= 290) {
        return '코';
      }

      // 입 영역
      if (y >= 315 && y <= 380 && x >= 180 && x <= 330) {
        return '입';
      }

      // 볼 영역
      if (y >= 210 && y <= 380) {
        return '볼';
      }

      // 턱 영역
      if (y >= 380 && y <= 430) {
        return '턱';
      }
      return '얼굴';
    } else {
      // female
      // 이마 (상단)
      if (y >= 100 && y <= 210) {
        return '이마';
      }

      // 눈 영역
      if (y >= 210 && y <= 310) {
        if (x >= 150 && x <= 220) return '눈';
        if (x >= 290 && x <= 360) return '눈';
      }

      // 귀 영역 (좌우 끝)
      if (y >= 180 && y <= 330) {
        if (x <= 100 || x >= 412) {
          return '귀';
        }
      }

      // 코 영역 (중앙)
      if (y >= 210 && y <= 320 && x >= 220 && x <= 290) {
        return '코';
      }

      // 입 영역
      if (y >= 320 && y <= 390 && x >= 190 && x <= 330) {
        return '입';
      }

      // 볼 영역
      if (y >= 210 && y <= 390) {
        return '볼';
      }

      // 턱 영역
      if (y >= 380 && y <= 440) {
        return '턱';
      }

      return '얼굴';
    }
  }

  void _onImageTapped(Offset imagePosition) {
    HapticFeedback.lightImpact();

    final bodyPart = _detectBodyPart(imagePosition.dx, imagePosition.dy);

    setState(() {
      markedPoint = imagePosition;
      detectedBodyPart = bodyPart;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Original image dimensions (PNG 원본 크기)
    const originalWidth = 512.0;
    const originalHeight = 512.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '얼굴',
          style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate actual displayed image size
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          // Account for aspect ratio with BoxFit.contain
          final imageAspectRatio = originalWidth / originalHeight;
          final screenAspectRatio = screenWidth / screenHeight;

          double displayWidth;
          double displayHeight;

          if (screenAspectRatio > imageAspectRatio) {
            // Screen is wider - height is constrained
            displayHeight = screenHeight;
            displayWidth = displayHeight * imageAspectRatio;
          } else {
            // Screen is taller - width is constrained
            displayWidth = screenWidth;
            displayHeight = displayWidth / imageAspectRatio;
          }

          return Stack(
            children: [
              // Gender toggle button (top right)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            isMale = true;
                            markedPoint = null;
                            detectedBodyPart = null;
                          });
                          _saveGenderPreference(true);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isMale
                                    ? AppColors.textPrimary
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            '남',
                            style: AppTextStyle.body.copyWith(
                              color:
                                  isMale
                                      ? Colors.white
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            isMale = false;
                            markedPoint = null;
                            detectedBodyPart = null;
                          });
                          _saveGenderPreference(false);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                !isMale
                                    ? AppColors.textPrimary
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            '여',
                            style: AppTextStyle.body.copyWith(
                              color:
                                  !isMale
                                      ? Colors.white
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final localPosition = renderBox.globalToLocal(
                      details.globalPosition,
                    );

                    // Calculate image position on screen (centered)
                    final centerOffsetX = (screenWidth - displayWidth) / 2;
                    final centerOffsetY = (screenHeight - displayHeight) / 2;

                    // Convert to display coordinates (relative to image)
                    final displayX = localPosition.dx - centerOffsetX;
                    final displayY = localPosition.dy - centerOffsetY;

                    // Check if within image bounds
                    if (displayX >= 0 &&
                        displayX <= displayWidth &&
                        displayY >= 0 &&
                        displayY <= displayHeight) {
                      // Convert to original image coordinates (normalized)
                      final originalX =
                          (displayX / displayWidth) * originalWidth;
                      final originalY =
                          (displayY / displayHeight) * originalHeight;

                      _onImageTapped(Offset(originalX, originalY));
                    }
                  },
                  child: Hero(
                    tag: 'body_part_face',
                    child: Image.asset(
                      isMale
                          ? 'assets/images/bodymap/face.png'
                          : 'assets/images/bodymap/face_woman.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Body part name and coordinates display (below image)
              if (detectedBodyPart != null && markedPoint != null)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            detectedBodyPart!,
                            style: AppTextStyle.subTitle.copyWith(
                              color: AppColors.background,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'X: ${markedPoint!.dx.toStringAsFixed(1)}, Y: ${markedPoint!.dy.toStringAsFixed(1)}',
                            style: AppTextStyle.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Draw red dot for marked point
              if (markedPoint != null)
                IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: Stack(
                        children: [
                          Positioned(
                            // Convert original coordinates back to display coordinates
                            left:
                                (markedPoint!.dx / originalWidth) *
                                    displayWidth -
                                6,
                            top:
                                (markedPoint!.dy / originalHeight) *
                                    displayHeight -
                                6,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton:
          markedPoint != null && detectedBodyPart != null
              ? FloatingActionButton.extended(
                onPressed: () async {
                  HapticFeedback.mediumImpact();

                  // 부위명으로 DB에서 spot 찾기
                  final spots = await DatabaseService().getSpots();
                  final spot = spots.firstWhere(
                    (s) => s['spot_name'] == detectedBodyPart,
                  );

                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RecordFormPage(
                              selectedDate: DateTime.now(),
                              selectedSpot: spot,
                            ),
                      ),
                    );
                  }
                },
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  '기록 추가',
                  style: AppTextStyle.body.copyWith(color: Colors.white),
                ),
              )
              : null,
    );
  }
}
