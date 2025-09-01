// calendar_bottom_sheet_handle.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/records/screens/record_form_page.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/widgets/drag_handle.dart';

class CalendarBottomSheetHandle extends StatefulWidget {
  final List<Map<String, dynamic>> dayRecords;
  final DateTime? selectedDay;
  final double currentHeight;
  final Function(double) onHeightChanged;
  final Map<String, dynamic>? selectedRecord;
  final int currentPageIndex;
  final VoidCallback onBackPressed;
  final VoidCallback? onRecordUpdated;
  final ValueChanged<DateTime> onDateChanged;

  const CalendarBottomSheetHandle({
    Key? key,
    required this.dayRecords,
    required this.selectedDay,
    required this.currentHeight,
    required this.onHeightChanged,
    required this.selectedRecord,
    required this.currentPageIndex,
    required this.onBackPressed,
    required this.onDateChanged,
    this.onRecordUpdated,
  }) : super(key: key);

  @override
  State<CalendarBottomSheetHandle> createState() =>
      _CalendarBottomSheetHandleState();
}

class _CalendarBottomSheetHandleState extends State<CalendarBottomSheetHandle> {
  double? _dragStartHeight;
  double? _dragStartDy;
  bool _isDragging = false;

  void _changeDay(int delta) {
    final base = widget.selectedDay;
    if (base == null) return;
    HapticFeedback.selectionClick();
    final newDate = DateTime(
      base.year,
      base.month,
      base.day,
    ).add(Duration(days: delta));
    widget.onDateChanged(newDate);
  }

  @override
  Widget build(BuildContext context) {
    final double dragGain = 3.0; // 드래그 민감도 가중치

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onVerticalDragStart: (details) {
        if (mounted) {
          setState(() {
            _isDragging = true;
            _dragStartHeight = widget.currentHeight; // 시작 높이 고정
            _dragStartDy = details.globalPosition.dy; // 시작 Y 고정
          });
        }
      },
      onVerticalDragUpdate: (details) {
        if (!_isDragging) return;
        final screenH = MediaQuery.of(context).size.height;

        final dy = details.globalPosition.dy - (_dragStartDy ?? 0);
        double newHeight =
            (_dragStartHeight ?? widget.currentHeight) -
            (dy / screenH) * dragGain;
        newHeight = newHeight.clamp(0.0, 0.93);

        widget.onHeightChanged(newHeight);
      },
      onVerticalDragEnd: (details) {
        if (!_isDragging || !mounted) return;
        setState(() => _isDragging = false);

        final current = widget.currentHeight;
        const snapPoints = [0.0, 0.5, 0.93];

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
            DragHandle(),
            Padding(
              padding: context.paddingHorizSM,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        AnimatedSlide(
                          offset:
                              widget.currentPageIndex == 1
                                  ? Offset(0, 0)
                                  : Offset(1, 0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child:
                                widget.currentPageIndex == 1
                                    ? Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            LucideIcons.chevronLeft,
                                            size: 24,
                                            color: AppColors.textPrimary,
                                          ),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            widget.onBackPressed();
                                          },
                                        ),
                                        Text(
                                          widget.selectedRecord!['symptom_name'] ??
                                              '증상 없음',
                                          style: AppTextStyle.subTitle.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    )
                                    : Container(),
                          ),
                        ),
                        AnimatedSlide(
                          offset:
                              widget.currentPageIndex == 1
                                  ? Offset(-1, 0)
                                  : Offset(0, 0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child:
                                widget.currentPageIndex == 1
                                    ? Container()
                                    : Row(
                                      children: [
                                        Row(
                                          spacing: 8,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatDateHeader(
                                                widget.selectedDay!,
                                              ),
                                              style: AppTextStyle.subTitle
                                                  .copyWith(
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                            ),
                                            GestureDetector(
                                              onTap:
                                                  widget.selectedDay == null
                                                      ? null
                                                      : () {
                                                        _changeDay(-1);
                                                        HapticFeedback.lightImpact();
                                                      },
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  LucideIcons.chevronLeft,
                                                  size: 24,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap:
                                                  widget.selectedDay == null
                                                      ? null
                                                      : () {
                                                        _changeDay(1);
                                                        HapticFeedback.lightImpact();
                                                      },
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  LucideIcons.chevronRight,
                                                  size: 24,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: context.wp(2)),
                                        if (widget.dayRecords.isNotEmpty) ...[
                                          SizedBox(width: context.wp(2)),
                                          Container(
                                            padding: EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${widget.dayRecords.length}',
                                              style: AppTextStyle.caption
                                                  .copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onHeightChanged(0.0);
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
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
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }
}
