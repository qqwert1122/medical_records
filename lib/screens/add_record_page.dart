import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/widgets/add_record_date_widget.dart';
import 'package:medical_records/widgets/add_record_image_widget.dart';
import 'package:medical_records/widgets/add_record_memo_widget.dart';
import 'package:medical_records/widgets/add_record_spot_widget.dart';

class AddRecordPage extends StatefulWidget {
  @override
  _AddRecordPageState createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('기록 추가', style: AppTextStyle.title),
        backgroundColor: AppColors.background,
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AddRecordSpotWidget(),
              SizedBox(height: context.hp(2)),
              AddRecordDateWidget(),
              SizedBox(height: context.hp(2)),
              AddRecordMemoWidget(),
              SizedBox(height: context.hp(2)),
              AddRecordImageWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
