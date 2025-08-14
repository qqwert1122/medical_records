// calendar_bottom_sheet_handle.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarBottomSheetHandle extends StatefulWidget {
  final List<Map<String, dynamic>> dayRecords;
  final DateTime? selectedDay;
  final double currentHeight;
  final Function(double) onHeightChanged;
  final bool isDetailView;

  const CalendarBottomSheetHandle({
    Key? key,
    required this.dayRecords,
    required this.selectedDay,
    required this.currentHeight,
    required this.onHeightChanged,
    this.isDetailView = false,
  }) : super(key: key);

  @override
  State<CalendarBottomSheetHandle> createState() =>
      _CalendarBottomSheetHandleState();
}

class _CalendarBottomSheetHandleState extends State<CalendarBottomSheetHandle> {
  double? _dragStartHeight;
  double? _dragStartDy;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final double dragGain = 3.0; // 드래그 민감도 가중치

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onVerticalDragStart:
          widget.isDetailView
              ? null
              : (details) {
                setState(() {
                  _isDragging = true;
                  _dragStartHeight = widget.currentHeight; // 시작 높이 고정
                  _dragStartDy = details.globalPosition.dy; // 시작 Y 고정
                });
              },
      onVerticalDragUpdate:
          widget.isDetailView
              ? null
              : (details) {
                if (!_isDragging) return;
                final screenH = MediaQuery.of(context).size.height;

                final dy = details.globalPosition.dy - (_dragStartDy ?? 0);
                double newHeight =
                    (_dragStartHeight ?? widget.currentHeight) -
                    (dy / screenH) * dragGain;
                newHeight = newHeight.clamp(0.0, 0.9);

                widget.onHeightChanged(newHeight);
              },
      onVerticalDragEnd:
          widget.isDetailView
              ? null
              : (details) {
                if (!_isDragging) return;
                setState(() => _isDragging = false);

                final current = widget.currentHeight;
                const snapPoints = [0.0, 0.4, 0.9];

                // 속도 기반 스냅: 빠르게 위로 올리면 다음 스냅, 아래로 내리면 이전 스냅
                final v = details.primaryVelocity ?? 0.0;
                double target;
                const flingThreshold = 450; // 속도 민감도, 낮을수록 민감

                if (v.abs() > flingThreshold) {
                  if (v > 0) {
                    // 아래로 빠르게 끌었음 → 현재 이하에서 가장 가까운(이전) 스냅
                    target = snapPoints.lastWhere(
                      (p) => p <= current,
                      orElse: () => snapPoints.first,
                    );
                  } else {
                    // 위로 빠르게 끌었음 → 현재 이상에서 가장 가까운(다음) 스냅
                    target = snapPoints.firstWhere(
                      (p) => p >= current,
                      orElse: () => snapPoints.last,
                    );
                  }
                } else {
                  // 느리면 가장 가까운 스냅
                  target = snapPoints.reduce(
                    (a, b) => (current - a).abs() < (current - b).abs() ? a : b,
                  );
                }

                // 손 뗀 후에만 스냅 적용(부모에서 애니메이션)
                widget.onHeightChanged(target);
              },
      child: Container(
        width: double.infinity,
        color: Colors.transparent,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Container(
              width: context.wp(15),
              height: context.hp(0.5),
              margin: EdgeInsets.symmetric(vertical: context.hp(1.5)),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Padding(
              padding: context.paddingHorizSM,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5.0,
                    children: [
                      Text(
                        _formatDateHeader(widget.selectedDay!),
                        style: AppTextStyle.title,
                      ),
                      if (widget.dayRecords.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${widget.dayRecords.length}개',
                            style: AppTextStyle.caption.copyWith(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: context.xl,
                      color: AppColors.grey,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onHeightChanged(0.0);
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(date.year, date.month, date.day);

    if (inputDate == today) {
      return '오늘';
    } else if (date.year == now.year) {
      return '${date.month}월 ${date.day}일';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일)';
    }
  }
}
