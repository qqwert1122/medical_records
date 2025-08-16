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
  final GlobalKey<RecordFoamDateWidgetState> _startDateKey = GlobalKey();
  final GlobalKey<RecordFoamDateWidgetState> _endDateKey = GlobalKey();
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
    final histories = await DatabaseService().getHistories(
      widget.recordData!['record_id'],
    );

    final initialHistory = histories.firstWhere(
      (h) => h['event_type'] == 'INITIAL',
      orElse: () => histories.first,
    );

    final images = await DatabaseService().getImages(
      initialHistory['history_id'],
    );

    return images.map((img) => img['image_url'] as String).toList();
  }

  void saveRecord() async {
    final spot = _spotKey.currentState?.getSelectedSpot();
    final symptom = _symptomKey.currentState?.getSelectedSymptom();
    final startDate = _startDateKey.currentState?.getSelectedDate();
    final endDate = _endDateKey.currentState?.getSelectedDate();
    final color = _colorKey.currentState?.getSelectedColor();
    final memo = _memoKey.currentState?.getMemo();
    final imagePaths = _imageKey.currentState?.getSelectedImagePaths();

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

    if (startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('시작 날짜를 선택해주세요.')));
      return;
    }

    // 종료일이 시작일보다 이전인지 검증
    if (endDate != null && endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('종료일은 시작일 이후여야 합니다.')));
      return;
    }

    try {
      int recordId;
      int historyId;
      final strStartDate = startDate.toIso8601String();
      final strEndDate = endDate?.toIso8601String();

      if (isEditMode) {
        // 수정 모드
        recordId = widget.recordData!['record_id'];

        // 종료일 변경에 따른 status 업데이트
        String status = widget.recordData!['status'];
        final wasComplete = status == 'COMPLETE';

        if (strEndDate != null && status == 'PROGRESS') {
          status = 'COMPLETE';
        } else if (strEndDate == null && status == 'COMPLETE') {
          status = 'PROGRESS';
        }

        await DatabaseService().updateRecord(
          recordId: recordId,
          status: status,
          color: color!.toARGB32().toString(),
          spotId: spot['spot_id'],
          spotName: spot['spot_name'],
          symptomId: symptom['symptom_id'],
          symptomName: symptom['symptom_name'],
          startDate: strStartDate,
          endDate: strEndDate,
        );

        // INITIAL history Update
        final histories = await DatabaseService().getHistories(recordId);
        final initialHistory = histories.firstWhere(
          (h) => h['event_type'] == 'INITIAL',
          orElse: () => histories.first,
        );

        await DatabaseService().updateHistory(
          historyId: initialHistory['history_id'],
          eventType: 'INITIAL',
          memo: memo,
          recordDate: strStartDate,
        );

        historyId = initialHistory['history_id'];

        if (!wasComplete && strEndDate != null) {
          await DatabaseService().createHistory(
            recordId: recordId,
            eventType: 'COMPLETE',
            recordDate: strEndDate,
            memo: '증상 종료',
          );
        } else if (wasComplete && strEndDate != null) {
          // COMPLETE history 날짜 업데이트
          final completeHistory = histories.firstWhere(
            (h) => h['event_type'] == 'COMPLETE',
            orElse: () => <String, dynamic>{},
          );
          if (completeHistory.isNotEmpty) {
            await DatabaseService().updateHistory(
              historyId: completeHistory['history_id'],
              eventType: 'COMPLETE',
              recordDate: strEndDate,
            );
          }
        }

        List<String> finalImagePaths = [];
        if (imagePaths != null && imagePaths.isNotEmpty) {
          for (String imagePath in imagePaths) {
            if (imagePath.contains('app_flutter/images/')) {
              finalImagePaths.add(imagePath);
            } else {
              final savedPath = await FileService().saveImageToAppStorage(
                imagePath,
              );
              finalImagePaths.add(savedPath);
            }
          }
        }

        await DatabaseService().deleteAllImagesByHistoryId(historyId);
        if (finalImagePaths.isNotEmpty) {
          await DatabaseService().saveImages(historyId, finalImagePaths);
        }
      } else {
        // 생성 모드

        final status = strEndDate != null ? 'COMPLETE' : 'PROGRESS';

        recordId = await DatabaseService().createRecord(
          status: status,
          color: color!.toARGB32().toString(),
          spotId: spot['spot_id'],
          spotName: spot['spot_name'],
          symptomId: symptom['symptom_id'],
          symptomName: symptom['symptom_name'],
          startDate: strStartDate,
          endDate: strEndDate,
          initialMemo: memo,
        );
        final histories = await DatabaseService().getHistories(recordId);
        historyId = histories.first['history_id'];

        if (imagePaths != null && imagePaths.isNotEmpty) {
          final savedImagePaths = await FileService().saveImagesToAppStorage(
            imagePaths,
          );
          if (savedImagePaths.isNotEmpty) {
            await DatabaseService().saveImages(historyId, savedImagePaths);
          }
        }

        // 종료일이 있으면 COMPLETE history도 자동 생성
        if (strEndDate != null) {
          await DatabaseService().createHistory(
            recordId: recordId,
            eventType: 'COMPLETE',
            recordDate: strEndDate,
            memo: '증상 종료',
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditMode ? '기록이 수정되었습니다.' : '기록이 저장되었습니다.')),
      );

      Navigator.of(context).pop(true);
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
                    RecordFoamColorWidget(
                      key: _colorKey,
                      initialColor:
                          isEditMode
                              ? Color(int.parse(widget.recordData!['color']))
                              : null,
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
                    SizedBox(height: context.hp(1)),
                    // 시작일
                    RecordFoamDateWidget(
                      key: _startDateKey,
                      initialDate:
                          isEditMode
                              ? DateTime.parse(widget.recordData!['start_date'])
                              : widget.selectedDate,
                      onTap: () async {
                        // 시작일 선택 시 종료일 가져오기
                        final endDate =
                            _endDateKey.currentState?.getSelectedDate();
                        return endDate;
                      },
                      onDateChanged: (DateTime? date) {
                        // 시작일 변경 시 종료일 체크
                        if (date != null) {
                          final endDate =
                              _endDateKey.currentState?.getSelectedDate();
                          if (endDate != null && endDate.isBefore(date)) {
                            _endDateKey.currentState?.setSelectedDate(date);
                          }
                        }
                      },
                    ),
                    SizedBox(height: context.hp(1)),
                    // 종료일 (선택사항)
                    RecordFoamDateWidget(
                      key: _endDateKey,
                      initialDate:
                          isEditMode && widget.recordData!['end_date'] != null
                              ? DateTime.parse(widget.recordData!['end_date'])
                              : null,
                      isOptional: true, // 선택사항 표시
                      onTap: () async {
                        // 종료일 선택 시 시작일을 minDate로 전달
                        final startDate =
                            _startDateKey.currentState?.getSelectedDate();
                        return startDate;
                      },
                    ),
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
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '저장',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
