import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/features/form/screens/record_form_page.dart';

class MouthDetailPage extends StatefulWidget {
  const MouthDetailPage({super.key});

  @override
  State<MouthDetailPage> createState() => _MouthDetailPageState();
}

class _MouthDetailPageState extends State<MouthDetailPage> {
  Offset? markedPoint;
  String? detectedBodyPart;

  String? _detectBodyPart(double x, double y) {
    // 256x256 이미지 기준 좌표
    // 중앙 X = 128

    // 윗입술
    if (y >= 10 && y <= 45) {
      return '윗입술';
    }

    // 윗잇몸
    if (y >= 45 && y <= 70 && x >= 50 && x <= 200) {
      return '윗잇몸';
    }

    // 윗이빨
    if (y >= 70 && y <= 95 && x >= 50 && x <= 200) {
      return '윗이빨';
    }

    // 입천장 (상단 내부)
    if (y >= 95 && y <= 105 && x >= 50 && x <= 200) {
      return '입천장';
    }

    // 목젓 (중앙 상단 안쪽)
    if (y >= 100 && y <= 130 && x >= 115 && x <= 140) {
      return '목젖';
    }

    // 목구멍 (후방 중앙)
    if (y >= 105 && y <= 130 && x >= 80 && x <= 170) {
      return '목구멍';
    }

    // 혓바닥 (하단 내부)
    if (y >= 130 && y <= 180 && x >= 75 && x <= 175) {
      return '혓바닥';
    }

    // 볼 안쪽 (좌우 끝)
    if (y >= 100 && y <= 140) {
      if (x <= 80 || x >= 60) {
        return '볼 안쪽';
      }
      if (x <= 200 || x >= 175) {
        return '볼 안쪽';
      }
    }

    // 아랫이빨
    if (y >= 140 &&
        y <= 180 &&
        ((x >= 55 && x <= 80) || (x >= 175 && x <= 200))) {
      return '아랫이빨';
    }

    // 아랫이빨
    if (y >= 180 && y <= 200 && x >= 65 && x <= 185) {
      return '아랫이빨';
    }

    // 아랫잇몸
    if (y >= 200 && y <= 215 && x >= 50 && x <= 200) {
      return '아랫잇몸';
    }

    // 아랫입술
    if (y >= 215 && y <= 245) {
      return '아랫입술';
    }

    return '입';
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
    const originalWidth = 256.0;
    const originalHeight = 256.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '입',
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
              // Body part name display at top
              if (detectedBodyPart != null)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        detectedBodyPart!,
                        style: AppTextStyle.body.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              // Debug coordinate display
              if (markedPoint != null)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'X: ${markedPoint!.dx.toStringAsFixed(1)}, Y: ${markedPoint!.dy.toStringAsFixed(1)}',
                        style: AppTextStyle.caption.copyWith(
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
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
                    tag: 'body_part_mouth',
                    child: Image.asset(
                      'assets/images/bodymap/mouth.png',
                      fit: BoxFit.contain,
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
