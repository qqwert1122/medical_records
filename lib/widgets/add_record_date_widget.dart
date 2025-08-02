import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/widgets/date_picker_bottom_sheet.dart';

class AddRecordDateWidget extends StatefulWidget {
  const AddRecordDateWidget({super.key});

  @override
  State<AddRecordDateWidget> createState() => AddRecordDateWidgetState();
}

class AddRecordDateWidgetState extends State<AddRecordDateWidget> {
  DateTime _selectedDate = DateTime.now();

  DateTime getSelectedDate() {
    return _selectedDate;
  }

  Future<void> _showDatePicker() async {
    final picked = await _showCustomDatePicker(context, _selectedDate);
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  static Future<DateTime?> _showCustomDatePicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    return await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DatePickerBottomSheet(initialDate: initialDate);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('날짜', style: AppTextStyle.subTitle),
        SizedBox(width: context.wp(4)),
        GestureDetector(
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
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: AppTextStyle.body,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
