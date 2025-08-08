import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordFoamMemoWidget extends StatefulWidget {
  final String? initialMemo;

  const RecordFoamMemoWidget({super.key, this.initialMemo});

  @override
  State<RecordFoamMemoWidget> createState() => RecordFoamMemoWidgetState();
}

class RecordFoamMemoWidgetState extends State<RecordFoamMemoWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialMemo ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getMemo() {
    return _controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
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
      maxLines: 3,
    );
  }
}
