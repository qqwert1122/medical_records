import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/records/widgets/date_picker_bottom_sheet.dart';
import 'package:medical_records/utils/time_format.dart';

class RecordFoamDateWidget extends StatefulWidget {
  final DateTime? initialDate;
  final bool isOptional;
  final Future<DateTime?> Function()? onTap;
  final void Function(DateTime?)? onDateChanged;

  const RecordFoamDateWidget({
    super.key,
    this.initialDate,
    this.isOptional = false,
    this.onTap,
    this.onDateChanged,
  });

  @override
  State<RecordFoamDateWidget> createState() => RecordFoamDateWidgetState();
}

class RecordFoamDateWidgetState extends State<RecordFoamDateWidget> {
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
              ? _initialNow
              : _midnight(widget.initialDate!);
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

  Future<void> _showDatePicker() async {
    DateTime? minDate;
    if (widget.isOptional && widget.onTap != null) {
      minDate = await widget.onTap!();
    }
    DateTime initialDate;
    if (_selectedDate != null) {
      // 선택된 날짜가 오늘이면 현재 시각으로 열기
      initialDate = _selectedDate!;
    } else {
      initialDate = minDate ?? DateTime.now();
    }

    final picked = await _showCustomDatePicker(
      context,
      initialDate,
      minDate: minDate,
    );
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
  }

  static Future<DateTime?> _showCustomDatePicker(
    BuildContext context,
    DateTime initialDate, {
    DateTime? minDate,
  }) async {
    return await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DateTimePickerBottomSheet(
          initialDate: initialDate,
          minDate: minDate,
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
          width: context.wp(12),
          child: Text(
            !widget.isOptional ? '시작일' : '종료일',
            style: AppTextStyle.body.copyWith(fontWeight: FontWeight.bold),
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
                    color: AppColors.primary,
                  ),
                  SizedBox(width: context.wp(2)),
                  Text(
                    _selectedDate != null
                        ? TimeFormat.getAbsoluteAmPm(
                          _selectedDate!.toIso8601String(),
                        )
                        : '선택 안함',
                    style: AppTextStyle.body,
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
                        color: AppColors.grey,
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
