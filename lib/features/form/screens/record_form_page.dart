import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/services/file_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/features/form/widgets/record_form_color_widget.dart';
import 'package:medical_records/features/form/widgets/record_form_date_widget.dart';
import 'package:medical_records/features/form/widgets/record_form_image_widget.dart';
import 'package:medical_records/features/form/widgets/record_form_memo_widget.dart';
import 'package:medical_records/features/form/widgets/record_form_spot_widget.dart';
import 'package:medical_records/features/form/widgets/record_form_symptom_widget.dart';
import 'package:medical_records/components/drag_handle.dart';
import 'package:uuid/uuid.dart';

class RecordFormPage extends StatefulWidget {
  final Map<String, dynamic>? recordData;
  final DateTime? selectedDate;
  final Map<String, dynamic>? selectedSpot;

  const RecordFormPage({
    super.key,
    this.recordData,
    this.selectedDate,
    this.selectedSpot,
  });

  @override
  _RecordFormPageState createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  bool get isEditMode => widget.recordData != null;
  List<String>? _existingImages;
  bool _isLoading = true;

  final GlobalKey<RecordFormSpotWidgetState> _spotKey = GlobalKey();
  final GlobalKey<RecordFormSymptomWidgetState> _symptomKey = GlobalKey();
  final GlobalKey<RecordFormDateWidgetState> _startDateKey = GlobalKey();
  final GlobalKey<RecordFormDateWidgetState> _endDateKey = GlobalKey();
  final GlobalKey<RecordFormColorWidgetState> _colorKey = GlobalKey();
  final GlobalKey<RecordFormMemoWidgetState> _memoKey = GlobalKey();
  final GlobalKey<RecordFormImageWidgetState> _imageKey = GlobalKey();

  bool get _isFormValid {
    final spot = _spotKey.currentState?.getSelectedSpot();
    final symptom = _symptomKey.currentState?.getSelectedSymptom();
    final startDate = _startDateKey.currentState?.getSelectedDate();
    final color = _colorKey.currentState?.getSelectedColor();

    return spot != null &&
        symptom != null &&
        startDate != null &&
        color != null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (isEditMode) {
      _existingImages = await _getExistingImages();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<DateTime?> _getLastHistoryDate() async {
    if (!isEditMode) return null;

    final histories = await DatabaseService().getHistories(
      widget.recordData!['record_id'],
    );

    if (histories.isEmpty) return null;

    // INITIAL과 COMPLETE를 제외한 history 중 가장 최근 날짜 찾기
    DateTime? lastDate;
    for (var history in histories) {
      if (history['event_type'] != 'INITIAL' &&
          history['event_type'] != 'COMPLETE') {
        final date = DateTime.parse(history['record_date']);
        if (lastDate == null || date.isAfter(lastDate)) {
          lastDate = date;
        }
      }
    }

    return lastDate;
  }

  Future<DateTime?> _getEarliestAfterInitialDate() async {
    if (!isEditMode) return null;

    final histories = await DatabaseService().getHistories(
      widget.recordData!['record_id'],
    );

    if (histories.isEmpty) return null;

    DateTime? earliest;
    for (var h in histories) {
      if (h['event_type'] == 'INITIAL') continue;
      final s = h['record_date'] ?? h['event_date'];
      if (s == null) continue;
      final d = DateTime.parse(s);
      if (earliest == null || d.isBefore(earliest)) earliest = d;
    }
    return earliest;
  }

  DateTime? _minDt(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  DateTime? _maxDt(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  DateTime? _exclusiveMin(DateTime? dt) => dt?.add(const Duration(minutes: 1));
  DateTime? _exclusiveMax(DateTime? dt) =>
      dt?.subtract(const Duration(minutes: 1));

  void saveRecord() async {
    // TODOLIST 증상, 부위 count++
    // TODOLIST history의 record_date와 record의 end_date 불일치
    // TODOLIST 타임라인의 증상 종료 클릭 시 history가 생성 안되는 이슈
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
        final previousEndDate = widget.recordData!['end_date'];

        if (strEndDate != null && status == 'PROGRESS') {
          status = 'COMPLETE';
        } else if (strEndDate == null && previousEndDate != null) {
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

        if (previousEndDate == null && strEndDate != null) {
          // PROGRESS → COMPLETE: COMPLETE history 생성
          print('PROGRESS → COMPLETE: COMPLETE history 생성');
          await DatabaseService().createHistory(
            recordId: recordId,
            eventType: 'COMPLETE',
            recordDate: strEndDate,
            memo: '',
          );
        } else if (previousEndDate != null && strEndDate == null) {
          // COMPLETE → PROGRESS: COMPLETE history 삭제
          print('COMPLETE → PROGRESS: COMPLETE history 삭제');
          final completeHistory = histories.firstWhere(
            (h) => h['event_type'] == 'COMPLETE',
            orElse: () => <String, dynamic>{},
          );
          if (completeHistory.isNotEmpty) {
            await DatabaseService().deleteHistory(
              completeHistory['history_id'],
            );
          }
        } else if (previousEndDate != null && strEndDate != null) {
          // COMPLETE 날짜만 변경
          print('COMPLETE 날짜만 변경');
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
            memo: '',
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

  Widget _buildTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 5, bottom: 10),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTextStyle.body.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: context.hp(95),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (FocusScope.of(context).hasFocus) {
          FocusScope.of(context).unfocus();
        }
      },

      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: SizedBox(
          height: context.hp(95),
          child: Column(
            children: [
              DragHandle(),
              Padding(
                padding: context.paddingSM,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.backgroundSecondary,
                        ),
                        child: Icon(
                          LucideIcons.x,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      isEditMode ? '기록 수정' : '기록 추가',
                      style: AppTextStyle.subTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _isFormValid
                            ? () {
                              HapticFeedback.lightImpact();
                              saveRecord();
                            }
                            : null;
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: Icon(
                          LucideIcons.plus,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: context.paddingSM,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RecordFormSymptomWidget(
                          key: _symptomKey,
                          initialSymptomId:
                              isEditMode
                                  ? widget.recordData!['symptom_id']
                                  : null,
                          onChanged: () => setState(() {}),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.surface,
                        ),
                        RecordFormSpotWidget(
                          key: _spotKey,
                          initialSpotId:
                              isEditMode
                                  ? widget.recordData!['spot_id']
                                  : widget.selectedSpot?['spot_id'],
                          onChanged: () => setState(() {}),
                        ),
                        SizedBox(height: 16),
                        // 시작일
                        RecordFormDateWidget(
                          key: _startDateKey,
                          initialDate:
                              isEditMode
                                  ? DateTime.parse(
                                    widget.recordData!['start_date'],
                                  )
                                  : null,
                          boundsResolver: () async {
                            DateTime? maxByNext =
                                await _getEarliestAfterInitialDate();
                            if (maxByNext != null) {
                              maxByNext = _exclusiveMax(maxByNext); // next - 1분
                            }

                            DateTime? currentEnd =
                                _endDateKey.currentState?.getSelectedDate() ??
                                (isEditMode &&
                                        widget.recordData!['end_date'] != null
                                    ? DateTime.parse(
                                      widget.recordData!['end_date'],
                                    )
                                    : null);
                            if (currentEnd != null) {
                              currentEnd = _exclusiveMax(
                                currentEnd,
                              ); // end - 1분
                            }
                            final maxDate = _minDt(
                              _minDt(maxByNext, currentEnd),
                              DateTime.now(),
                            );
                            return (null, maxDate);
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
                            setState(() {});
                          },
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.surface,
                        ),
                        // 종료일 (선택사항)
                        RecordFormDateWidget(
                          key: _endDateKey,
                          initialDate:
                              isEditMode &&
                                      widget.recordData!['end_date'] != null
                                  ? DateTime.parse(
                                    widget.recordData!['end_date'],
                                  )
                                  : null,
                          isOptional: true, // 선택사항 표시
                          boundsResolver: () async {
                            // 폼에서 선택된 시작일(없으면 레코드의 start_date)
                            final DateTime? startDate =
                                _startDateKey.currentState?.getSelectedDate() ??
                                (isEditMode
                                    ? DateTime.parse(
                                      widget.recordData!['start_date'],
                                    )
                                    : null);

                            // INITIAL/COMPLETE 제외한 일반 히스토리 중 가장 최신 record_date
                            final DateTime? lastNormal =
                                await _getLastHistoryDate();

                            // 최소 기준 = max(시작일, 마지막 일반 히스토리)
                            DateTime? minBase = _maxDt(startDate, lastNormal);

                            // 배타(>)로 만들고 싶다면 +1분
                            final DateTime? minDate = _exclusiveMin(minBase);

                            // 최대는 보통 현재 시각
                            final DateTime maxDate = DateTime.now();

                            return (minDate, maxDate);
                          },
                        ),
                        SizedBox(height: 16),

                        RecordFormMemoWidget(
                          key: _memoKey,
                          initialMemo:
                              isEditMode ? widget.recordData!['memo'] : null,
                        ),
                        SizedBox(height: 16),

                        // 색상
                        RecordFormColorWidget(
                          key: _colorKey,
                          initialColor:
                              isEditMode
                                  ? Color(
                                    int.parse(widget.recordData!['color']),
                                  )
                                  : Colors.pinkAccent.shade400,
                          onChanged: () => setState(() {}),
                        ),
                        SizedBox(height: 16),

                        // 이미지
                        RecordFormImageWidget(
                          key: _imageKey,
                          initialImagePaths: _existingImages,
                        ),
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
