import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/features/form/widgets/date_picker_bottom_sheet.dart';
import 'package:medical_records/utils/time_format.dart';

class RecordFormDateWidget extends StatefulWidget {
  final DateTime? initialDate;
  final bool isOptional;
  final Future<(DateTime?, DateTime?)> Function()? boundsResolver;
  final void Function(DateTime?)? onDateChanged;

  const RecordFormDateWidget({
    super.key,
    this.initialDate,
    this.isOptional = false,
    this.boundsResolver,
    this.onDateChanged,
  });

  @override
  State<RecordFormDateWidget> createState() => RecordFormDateWidgetState();
}

class RecordFormDateWidgetState extends State<RecordFormDateWidget> {
  DateTime? _selectedDate;
  late DateTime _initialNow;

  bool _isToday(DateTime d) => DateUtils.isSameDay(d, DateTime.now());
  DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _initialNow = DateTime.now();
    if (widget.initialDate != null) {
      _selectedDate =
          _isToday(widget.initialDate!)
              ? _initialNow // 오늘이면 now
              : _midnight(widget.initialDate!); // 과거이면 자정
    } else {
      _selectedDate = widget.isOptional ? null : _initialNow;
    }
  }

  DateTime? getSelectedDate() => _selectedDate;
  void setSelectedDate(DateTime? date) {
    if (mounted) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  DateTime _clampToBounds(DateTime value, {DateTime? min, DateTime? max}) {
    if (min != null && value.isBefore(min)) return min;
    if (max != null && value.isAfter(max)) return max;
    return value;
  }

  Future<void> _showDatePicker() async {
    // 1) 경계 계산 (없으면 null 사용)
    DateTime? minDate;
    DateTime? maxDate;
    if (widget.boundsResolver != null) {
      final (min, max) = await widget.boundsResolver!.call();
      minDate = min;
      maxDate = max;
    }

    // 2) 초기 표시값 결정 + 경계 클램프
    DateTime initialDate = _selectedDate ?? (minDate ?? DateTime.now());
    initialDate = _clampToBounds(initialDate, min: minDate, max: maxDate);

    // 3) 바텀시트 호출
    final picked = await _showCustomDatePicker(
      context,
      initialDate,
      minDate: minDate,
      maxDate: maxDate,
    );

    // 4) 반영
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateChanged?.call(picked);
    }
  }

  void _clearDate() {
    if (mounted) {
      setState(() {
        _selectedDate = null;
      });
    }
    widget.onDateChanged?.call(null);
  }

  static Future<DateTime?> _showCustomDatePicker(
    BuildContext context,
    DateTime initialDate, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DateTimePickerBottomSheet(
          initialDate: initialDate,
          minDate: minDate,
          maxDate: maxDate,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(widget.isOptional ? 0 : 24.0),
          topLeft: Radius.circular(widget.isOptional ? 0 : 24.0),
          bottomRight: Radius.circular(widget.isOptional ? 24.0 : 0),
          bottomLeft: Radius.circular(widget.isOptional ? 24.0 : 0),
        ),
        color: AppColors.background,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Text(
                !widget.isOptional ? '시작일' : '종료일',
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              !widget.isOptional
                  ? Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  )
                  : SizedBox(width: 6, height: 6),
            ],
          ),
          SizedBox(width: 16),
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                _showDatePicker();
              },
              child: Row(
                children: [
                  Spacer(),
                  _selectedDate != null
                      ? Icon(
                        LucideIcons.calendarDays,
                        size: 18,
                        color: AppColors.textSecondary,
                      )
                      : SizedBox(),
                  SizedBox(width: 8),
                  Text(
                    _selectedDate != null
                        ? TimeFormat.getSimpleDateTime(
                          _selectedDate!.toIso8601String(),
                        )
                        : '없음',
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8),
                  _selectedDate != null && widget.isOptional
                      ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _clearDate();
                        },
                        child: Container(
                          padding: EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.backgroundSecondary,
                          ),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                      : Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: AppColors.textSecondary,
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
