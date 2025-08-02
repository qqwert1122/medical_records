import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/widgets/add_record_date_widget.dart';
import 'package:medical_records/widgets/add_record_image_widget.dart';
import 'package:medical_records/widgets/add_record_memo_widget.dart';
import 'package:medical_records/widgets/add_record_spot_widget.dart';
import 'package:medical_records/widgets/add_record_symptom_widget.dart';

class AddRecordPage extends StatefulWidget {
  @override
  _AddRecordPageState createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final GlobalKey<AddRecordSpotWidgetState> _spotKey = GlobalKey();
  final GlobalKey<AddRecordSymptomWidgetState> _symptomKey = GlobalKey();
  final GlobalKey<AddRecordDateWidgetState> _dateKey = GlobalKey();
  final GlobalKey<AddRecordMemoWidgetState> _memoKey = GlobalKey();
  final GlobalKey<AddRecordImageWidgetState> _imageKey = GlobalKey();

  void saveRecord() async {
    final spot = _spotKey.currentState?.getSelectedSpot();
    final symtpom = _symptomKey.currentState?.getSelectedSymptom();
    final date = _dateKey.currentState?.getSelectedDate();
    final memo = _memoKey.currentState?.getMemo();
    final imagePaths = _imageKey.currentState?.getSelectedImagePaths();

    if (spot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('위치를 선택해주세요.')));
      return;
    }

    try {
      final recordId = await DatabaseService().createRecord(
        memo: memo ?? '',
        spotId: spot['spot_id'],
        spotName: spot['spot_name'],
        spotColor: spot['spot_color'],
        historiesId: null,
      );

      if (imagePaths != null && imagePaths.isNotEmpty) {
        await DatabaseService().saveImages(recordId, imagePaths);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('기록이 저장되었습니다.')));

      Navigator.of(context).pop();
    } catch (e) {
      print('저장 중 오류가 발생했습니다: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
    }
  }

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
              AddRecordSpotWidget(key: _spotKey),
              SizedBox(height: context.hp(2)),
              AddRecordSymptomWidget(key: _symptomKey),
              SizedBox(height: context.hp(2)),
              AddRecordDateWidget(key: _dateKey),
              SizedBox(height: context.hp(2)),
              AddRecordMemoWidget(key: _memoKey),
              SizedBox(height: context.hp(2)),
              AddRecordImageWidget(key: _imageKey),
              Spacer(),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '취소',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        SizedBox(width: context.wp(4)),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              saveRecord();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '저장',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
