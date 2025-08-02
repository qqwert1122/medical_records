import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class AddRecordMemoWidget extends StatefulWidget {
  const AddRecordMemoWidget({super.key});

  @override
  State<AddRecordMemoWidget> createState() => _AddRecordMemoWidgetState();
}

class _AddRecordMemoWidgetState extends State<AddRecordMemoWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('메모', style: AppTextStyle.subTitle),
        SizedBox(height: context.hp(1)),
        TextField(
          decoration: InputDecoration(
            hintText: '(선택) 증상에 대해 자세히 기록해주세요',
            hintStyle: AppTextStyle.hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          maxLines: 5,
        ),
      ],
    );
  }
}
