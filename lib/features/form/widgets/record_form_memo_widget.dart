import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordFormMemoWidget extends StatefulWidget {
  final String? initialMemo;

  const RecordFormMemoWidget({super.key, this.initialMemo});

  @override
  State<RecordFormMemoWidget> createState() => RecordFormMemoWidgetState();
}

class RecordFormMemoWidgetState extends State<RecordFormMemoWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialMemo ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String getMemo() {
    return _controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24.0)),
        color: AppColors.background,
      ),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(_focusNode);
        },
        child: TextField(
          autofocus: false,
          focusNode: _focusNode,
          onEditingComplete: () {
            _focusNode.unfocus();
          },
          style: AppTextStyle.body.copyWith(color: AppColors.textPrimary),
          controller: _controller,
          decoration: InputDecoration(
            hintText: '메모',
            hintStyle: AppTextStyle.body.copyWith(
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
          maxLines: 2,
        ),
      ),
    );
  }
}
