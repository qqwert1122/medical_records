// calendar_bottom_sheet_handle.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_size.dart';

class CalendarBottomSheetHandle extends StatefulWidget {
  final double currentHeight;
  final Function(double) onHeightChanged;
  final bool isDetailView;

  const CalendarBottomSheetHandle({
    Key? key,
    required this.currentHeight,
    required this.onHeightChanged,
    this.isDetailView = false,
  }) : super(key: key);

  @override
  State<CalendarBottomSheetHandle> createState() =>
      _CalendarBottomSheetHandleState();
}

class _CalendarBottomSheetHandleState extends State<CalendarBottomSheetHandle> {
  double _dragStartHeight = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart:
          widget.isDetailView
              ? null
              : (details) {
                setState(() {
                  _isDragging = true;
                  _dragStartHeight = widget.currentHeight;
                });
              },
      onVerticalDragUpdate:
          widget.isDetailView
              ? null
              : (details) {
                if (!_isDragging) return;

                double newHeight =
                    _dragStartHeight - (details.primaryDelta! / screenHeight);
                newHeight = newHeight.clamp(0.0, 0.9);
                widget.onHeightChanged(newHeight);
              },
      onVerticalDragEnd:
          widget.isDetailView
              ? null
              : (details) {
                if (!_isDragging) return;

                setState(() {
                  _isDragging = false;
                });

                final velocity = details.primaryVelocity ?? 0;

                if (velocity > 0) {
                  widget.onHeightChanged(0.0);
                } else {
                  widget.onHeightChanged(0.9);
                }

                HapticFeedback.lightImpact();
              },
      child: Container(
        width: double.infinity,
        height: 36,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Container(
          width: context.wp(15),
          height: context.hp(1),
          margin: EdgeInsets.symmetric(vertical: context.hp(1.5)),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
