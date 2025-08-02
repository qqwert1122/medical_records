import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class AddRecordImageWidget extends StatefulWidget {
  const AddRecordImageWidget({super.key});

  @override
  State<AddRecordImageWidget> createState() => _AddRecordImageWidgetState();
}

class _AddRecordImageWidgetState extends State<AddRecordImageWidget> {
  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(color: AppColors.grey, strokeWidth: 2, dashPattern: [6, 3], radius: Radius.circular(16)),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: 80,
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.imagePlus, size: 30, color: Colors.grey),
              SizedBox(height: 4),
              Text('사진 첨부', style: AppTextStyle.caption.copyWith(color: AppColors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
