import 'package:flutter/material.dart';
import 'package:medical_records/services/app_colors.dart';
import 'package:medical_records/services/app_size.dart';
import 'package:medical_records/widgets/image_list_widget.dart';

class RecordPage extends StatefulWidget {
  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: AppSize.hp(5)),
              Text(
                '입병의 위치를 기록하세요',
                style: TextStyle(
                  fontSize: AppSize.fontLG,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSize.hp(2)),
              Container(
                width: double.infinity,
                height: AppSize.hp(60),
                color: Colors.grey[300],
                child: Center(child: Text('입 사진')),
              ),
              SizedBox(height: AppSize.hp(2)),
              ImageListWidget(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,

        onPressed: () {},
        child: Icon(Icons.add, size: AppSize.fontXL),
        tooltip: '기록 추가',
      ),
    );
  }
}
