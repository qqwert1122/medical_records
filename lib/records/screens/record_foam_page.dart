import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/services/file_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/records/widgets/record_foam_color_widget.dart';
import 'package:medical_records/records/widgets/record_foam_date_widget.dart';
import 'package:medical_records/records/widgets/record_foam_image_widget.dart';
import 'package:medical_records/records/widgets/record_foam_memo_widget.dart';
import 'package:medical_records/records/widgets/record_foam_spot_widget.dart';
import 'package:medical_records/records/widgets/record_foam_symptom_widget.dart';
import 'package:uuid/uuid.dart';

class RecordFoamPage extends StatefulWidget {
  final Map<String, dynamic>? recordData;
  final DateTime? selectedDate;

  const RecordFoamPage({super.key, this.recordData, this.selectedDate});

  @override
  _RecordFoamPageState createState() => _RecordFoamPageState();
}

class _RecordFoamPageState extends State<RecordFoamPage> {
  bool get isEditMode => widget.recordData != null;
  List<String>? _existingImages;
  bool _isLoading = true;

  final GlobalKey<RecordFoamSpotWidgetState> _spotKey = GlobalKey();
  final GlobalKey<RecordFoamSymptomWidgetState> _symptomKey = GlobalKey();
  final GlobalKey<RecordFoamDateWidgetState> _dateKey = GlobalKey();
  final GlobalKey<RecordFoamColorWidgetState> _colorKey = GlobalKey();
  final GlobalKey<RecordFoamMemoWidgetState> _memoKey = GlobalKey();
  final GlobalKey<RecordFoamImageWidgetState> _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (isEditMode) {
      _existingImages = await _getExistingImages();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _getExistingImages() async {
    final images = await DatabaseService().getImages(
      widget.recordData!['record_id'],
    );

    return images.map((img) => img['image_url'] as String).toList();
  }

  void saveRecord() async {
    final spot = _spotKey.currentState?.getSelectedSpot();
    final symptom = _symptomKey.currentState?.getSelectedSymptom();
    final start_date = _dateKey.currentState?.getSelectedDate();
    final color = _colorKey.currentState?.getSelectedColor();
    final memo = _memoKey.currentState?.getMemo();
    final imagePaths = _imageKey.currentState?.getSelectedImagePaths();
    final historyId = const Uuid().v4();
    final strDate = start_date!.toIso8601String();

    if (spot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('위치를 선택해주세요.')));
      return;
    }

    if (symptom == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('증상을 선택해주세요.')));
      return;
    }

    try {
      int recordId;

      if (isEditMode) {
        // 수정 모드
        recordId = widget.recordData!['record_id'];

        List<String> finalImagePaths = [];

        if (imagePaths != null && imagePaths.isNotEmpty) {
          for (String imagePath in imagePaths) {
            if (imagePath.contains('app_flutter/images/')) {
              // 기존 이미지 - 그대로 유지
              finalImagePaths.add(imagePath);
            } else {
              // 새로 선택한 이미지 - 앱 내부로 복사
              final savedPath = await FileService().saveImageToAppStorage(
                imagePath,
              );
              finalImagePaths.add(savedPath);
            }
          }
        }

        await DatabaseService().updateRecord(
          recordId: recordId,
          type: 'INITIAL',
          historyId: widget.recordData!['history_id'],
          memo: memo ?? '',
          color: color!.toARGB32().toString(),
          spotId: spot['spot_id'],
          spotName: spot['spot_name'],
          symptomId: symptom['symptom_id'],
          symptomName: symptom['symptom_name'],
          startDate: strDate,
        );

        await DatabaseService().deleteAllImagesByRecordId(recordId);
        if (finalImagePaths.isNotEmpty) {
          await DatabaseService().saveImages(recordId, finalImagePaths);
        }
      } else {
        // 추가 모드
        recordId = await DatabaseService().createRecord(
          type: 'INITIAL',
          historyId: historyId,
          memo: memo ?? '',
          color: color!.toARGB32().toString(),
          spotId: spot['spot_id'],
          spotName: spot['spot_name'],
          symptomId: symptom['symptom_id'],
          symptomName: symptom['symptom_name'],
          startDate: strDate,
        );

        if (imagePaths != null && imagePaths.isNotEmpty) {
          final savedImagePaths = await FileService().saveImagesToAppStorage(
            imagePaths,
          );
          if (savedImagePaths.isNotEmpty) {
            await DatabaseService().saveImages(recordId, savedImagePaths);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditMode ? '기록이 수정되었습니다.' : '기록이 저장되었습니다.')),
      );

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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: Text(
            isEditMode ? '증상 수정' : '증상 추가',
            style: AppTextStyle.title,
          ),
          backgroundColor: AppColors.background,
        ),
        body: Center(child: CircularProgressIndicator(color: AppColors.black)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '기록 수정' : '기록 추가', style: AppTextStyle.title),
        backgroundColor: AppColors.background,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(color: AppColors.background),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 70), // 버튼 높이만큼 패딩
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이미지
                    RecordFoamImageWidget(
                      key: _imageKey,
                      initialImagePaths: _existingImages,
                    ),
                    SizedBox(height: context.hp(2)),
                    Row(
                      children: [
                        // 날짜
                        RecordFoamDateWidget(
                          key: _dateKey,
                          initialDate:
                              isEditMode
                                  ? DateTime.parse(widget.recordData!['date'])
                                  : widget.selectedDate ?? widget.selectedDate,
                        ),
                        SizedBox(width: context.wp(4)),
                        RecordFoamColorWidget(
                          key: _colorKey,
                          initialColor:
                              isEditMode
                                  ? Color(
                                    int.parse(widget.recordData!['color']),
                                  )
                                  : null,
                        ),
                      ],
                    ),
                    SizedBox(height: context.hp(1)),
                    RecordFoamSpotWidget(
                      key: _spotKey,
                      initialSpotId:
                          isEditMode ? widget.recordData!['spot_id'] : null,
                    ),
                    SizedBox(height: context.hp(1)),
                    RecordFoamSymptomWidget(
                      key: _symptomKey,
                      initialSymptomId:
                          isEditMode ? widget.recordData!['symptom_id'] : null,
                    ),
                    SizedBox(height: context.hp(1)),
                    RecordFoamMemoWidget(
                      key: _memoKey,
                      initialMemo:
                          isEditMode ? widget.recordData!['memo'] : null,
                    ),

                    // SizedBox(height: context.hp(2)),
                    SizedBox(height: context.hp(2)),
                  ],
                ),
              ),
              Positioned(bottom: 0, left: 0, right: 0, child: _buildButtons()),
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
              backgroundColor: AppColors.surface,
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
              backgroundColor: Colors.pinkAccent.shade100,
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
