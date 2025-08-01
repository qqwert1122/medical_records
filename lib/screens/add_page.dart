import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('기록 추가', style: AppTextStyle.title), backgroundColor: AppColors.surface),
      body: Container(
        decoration: BoxDecoration(color: AppColors.surface),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('날짜', style: AppTextStyle.subTitle),
                  SizedBox(width: AppSize.wp(4)),
                  Container(
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8.0)),
                    padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendarDays, size: AppSize.xl, color: AppColors.primary),
                        SizedBox(width: AppSize.wp(2)),
                        Text('2025-08-01', style: AppTextStyle.body),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSize.hp(2)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('메모', style: AppTextStyle.subTitle),
                  SizedBox(height: AppSize.hp(2)),
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    maxLines: 5,
                  ),
                ],
              ),
              SizedBox(height: AppSize.hp(2)),
              DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: AppColors.darkGrey,
                  strokeWidth: 2,
                  dashPattern: [6, 3],
                  radius: Radius.circular(16),
                ),
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
                        Text('사진 첨부', style: AppTextStyle.caption.copyWith(color: AppColors.darkGrey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
