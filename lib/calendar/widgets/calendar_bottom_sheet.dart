import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarBottomSheet extends StatelessWidget {
  final double bottomSheetHeight;
  final DateTime? selectedDay;
  final Map<DateTime, String> dayImages;
  final Function(double) onHeightChanged;
  final Function(DateTime) onDateChanged;

  const CalendarBottomSheet({
    Key? key,
    required this.bottomSheetHeight,
    required this.selectedDay,
    required this.dayImages,
    required this.onHeightChanged,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: 0,
      height: screenHeight * bottomSheetHeight,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          double newHeight =
              bottomSheetHeight - (details.delta.dy / screenHeight);
          onHeightChanged(newHeight.clamp(0.08, 1));
        },
        onVerticalDragEnd: (details) {
          // 속도 기반 처리 추가
          if (details.velocity.pixelsPerSecond.dy > 300) {
            // 빠르게 아래로 드래그
            onHeightChanged(0.08);
          } else if (details.velocity.pixelsPerSecond.dy < -300) {
            // 빠르게 위로 드래그
            onHeightChanged(1.0);
          } else {
            // 위치 기반 처리
            if (bottomSheetHeight < 0.15) {
              onHeightChanged(0.08);
            } else if (bottomSheetHeight < 0.5) {
              onHeightChanged(0.08);
            } else if (bottomSheetHeight < 0.9) {
              onHeightChanged(0.7);
            } else {
              onHeightChanged(1.0);
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                width: context.wp(15),
                height: context.hp(1),
                margin: EdgeInsets.symmetric(vertical: context.hp(1.5)),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // PageView
              if (bottomSheetHeight > 0.1 && selectedDay != null)
                Expanded(
                  child: PageView.builder(
                    controller: PageController(
                      initialPage:
                          selectedDay!.difference(DateTime(2020)).inDays,
                    ),
                    onPageChanged: (index) {
                      final date = DateTime(2020).add(Duration(days: index));
                      onDateChanged(date);
                    },
                    itemBuilder: (context, index) {
                      final date = DateTime(2020).add(Duration(days: index));
                      return Padding(
                        padding: EdgeInsets.all(context.wp(4)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.year}년 ${date.month}월 ${date.day}일',
                              style: AppTextStyle.subTitle,
                            ),
                            SizedBox(height: context.hp(2)),
                            Expanded(
                              child:
                                  dayImages.containsKey(date)
                                      ? Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.grey,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 100,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                      : Center(
                                        child: Text(
                                          '등록된 사진이 없습니다',
                                          style: AppTextStyle.body.copyWith(
                                            color: AppColors.grey,
                                          ),
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
