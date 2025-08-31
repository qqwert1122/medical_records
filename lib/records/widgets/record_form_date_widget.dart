import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/records/widgets/date_picker_bottom_sheet.dart';
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
    setState(() {
      _selectedDate = date;
    });
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
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateChanged?.call(picked);
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: context.wp(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4,
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
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                  : SizedBox(),
            ],
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showDatePicker();
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendarDays,
                    size: context.xl,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: context.wp(2)),
                  Text(
                    _selectedDate != null
                        ? TimeFormat.getDateTime(
                          _selectedDate!.toIso8601String(),
                        )
                        : '선택 안함',
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.isOptional && _selectedDate != null) ...[
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _clearDate();
                      },
                      child: Icon(
                        LucideIcons.x,
                        size: context.lg,
                        color: AppColors.lightGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
