import 'dart:ffi';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/histories/widgets/treatment_bottom_sheet.dart';
import 'package:medical_records/records/widgets/date_picker_bottom_sheet.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/services/file_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'dart:io';
import 'dart:math' as math;

import 'package:medical_records/widgets/drag_handle.dart';

class AddHistoryBottomSheet extends StatefulWidget {
  final int recordId;
  final String recordType; // 'PROGRESS' or 'TREATMENT'
  final DateTime? minDate;
  final bool isEditMode;
  final Map<String, dynamic>? existingHistory;

  const AddHistoryBottomSheet({
    Key? key,
    required this.recordId,
    required this.recordType,
    this.minDate,
    this.isEditMode = false,
    this.existingHistory,
  }) : super(key: key);

  @override
  State<AddHistoryBottomSheet> createState() => _AddHistoryBottomSheetState();
}

class _AddHistoryBottomSheetState extends State<AddHistoryBottomSheet> {
  // 초기값 세팅
  Map<String, dynamic>? selectedTreatment;
  DateTime _selectedDateTime = DateTime.now();
  final TextEditingController _memoController = TextEditingController();
  List<String> _imagePaths = [];
  bool _isPickingImages = false;

  // 날짜 제약
  DateTime? _initialDate;
  DateTime? _completeDate;
  DateTime? _lastHistoryDate;

  @override
  void initState() {
    _loadInitialTreatment();
    _loadDateConstraints();
    if (widget.isEditMode && widget.existingHistory != null) {
      _loadExistingData(); // 추가
    }
    super.initState();
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  DateTime? _exclusiveMin(DateTime? dt) => dt?.add(const Duration(minutes: 1));
  DateTime? _exclusiveMax(DateTime? dt) =>
      dt?.subtract(const Duration(minutes: 1));

  Future<void> _loadDateConstraints() async {
    if (widget.recordType == 'TREATMENT' || widget.recordType == 'PROGRESS') {
      final histories = await DatabaseService().getHistories(widget.recordId);

      final initialHistory = histories.firstWhere(
        (h) => h['event_type'] == 'INITIAL',
        orElse: () => {},
      );
      final completeHistory = histories.firstWhere(
        (h) => h['event_type'] == 'COMPLETE',
        orElse: () => {},
      );

      setState(() {
        _initialDate =
            (initialHistory.isNotEmpty && initialHistory['record_date'] != null)
                ? DateTime.parse(initialHistory['record_date'])
                : null;

        _completeDate =
            (completeHistory.isNotEmpty &&
                    completeHistory['record_date'] != null)
                ? DateTime.parse(completeHistory['record_date'])
                : null;
      });
    } else if (widget.recordType == 'COMPLETE') {
      final lastDate = await _getLastHistoryDate();
      setState(() {
        _lastHistoryDate = lastDate;
      });
    }
  }

  Future<(DateTime?, DateTime?)> _computeDateBounds() async {
    // COMPLETE: 마지막 일반 히스토리 '이후'만 허용
    if (widget.recordType == 'COMPLETE') {
      final minBase = _lastHistoryDate ?? await _getLastHistoryDate();
      final min = _exclusiveMin(minBase); // > last history
      final max = DateTime.now(); // now는 굳이 배타 안 해도 OK
      return (min, max);
    }

    // PROGRESS / TREATMENT
    if (widget.recordType == 'PROGRESS' || widget.recordType == 'TREATMENT') {
      // 기본 범위: INITIAL 이후, COMPLETE 이전
      final baseMin = _exclusiveMin(_initialDate); // > INITIAL
      final baseMax =
          _completeDate != null
              ? _exclusiveMax(_completeDate) // < COMPLETE
              : DateTime.now(); // COMPLETE 없으면 now까지

      // 신규 기록이면 기본 범위 반환
      if (!widget.isEditMode || widget.existingHistory == null) {
        return (baseMin, baseMax);
      }

      // 수정 기록이면 직전/직후 히스토리로 더 좁힘
      final histories = await _getHistoriesSorted();
      final currentId = widget.existingHistory!['history_id'];
      final idx = histories.indexWhere((h) => h['history_id'] == currentId);

      DateTime? prev; // 직전 히스토리 시각
      DateTime? next; // 직후 히스토리 시각

      if (idx != -1) {
        // prev
        for (int i = idx - 1; i >= 0; i--) {
          final s = histories[i]['record_date'] ?? histories[i]['event_date'];
          if (s != null) {
            prev = DateTime.parse(s);
            break;
          }
        }
        // next
        for (int i = idx + 1; i < histories.length; i++) {
          final s = histories[i]['record_date'] ?? histories[i]['event_date'];
          if (s != null) {
            next = DateTime.parse(s);
            break;
          }
        }
      }

      // 직전은 > prev, 직후는 < next 로 배타 처리
      final prevEx = _exclusiveMin(prev);
      final nextEx = _exclusiveMax(next);

      // 최종 min = max(baseMin, prevEx), max = min(baseMax, nextEx)
      DateTime? min = baseMin;
      if (prevEx != null) {
        min = (min == null) ? prevEx : (prevEx.isAfter(min) ? prevEx : min);
      }

      DateTime? max = baseMax;
      if (nextEx != null) {
        max = (max == null) ? nextEx : (nextEx.isBefore(max) ? nextEx : max);
      }

      // (옵션) 가드: 선택 가능 구간이 없을 때의 대비
      if (min != null && max != null && !min.isBefore(max)) {
        // 여기서는 그대로 반환해서 피커가 선택 불가 상태를 보여주게 두거나,
        // max를 min + 1분으로 살짝 열어줄 수도 있음 (선호에 따라 결정)
        // max = min.add(const Duration(minutes: 1));
      }

      return (min, max);
    }

    // 기본
    return (null, DateTime.now());
  }

  Future<List<Map<String, dynamic>>> _getHistoriesSorted() async {
    // UnmodifiableListView 방지: 가변 리스트로 복사
    final raw = await DatabaseService().getHistories(widget.recordId);
    final list = List<Map<String, dynamic>>.from(raw);

    DateTime? _p(dynamic s) {
      if (s == null) return null;
      try {
        return DateTime.parse(s as String);
      } catch (_) {
        return null;
      }
    }

    list.sort((a, b) {
      final ad = _p(a['record_date'] ?? a['event_date']);
      final bd = _p(b['record_date'] ?? b['event_date']);
      if (ad == null && bd == null) return 0; // 둘 다 없으면 그대로
      if (ad == null) return 1; // null을 뒤로
      if (bd == null) return -1;
      return ad.compareTo(bd); // 날짜만 비교
    });

    return list;
  }

  Future<DateTime?> _getLastHistoryDate() async {
    final histories = await DatabaseService().getHistories(widget.recordId);

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

  void _loadExistingData() async {
    final history = widget.existingHistory!;
    _selectedDateTime = DateTime.parse(history['record_date']);
    _memoController.text = history['memo'] ?? '';
    if (history['treatment_id'] != null) {
      selectedTreatment = {
        'treatment_id': history['treatment_id'],
        'treatment_name': history['treatment_name'],
      };
    }

    // 기존 이미지 로드
    final existingImages = await DatabaseService().getImages(
      history['history_id'],
    );
    if (existingImages.isNotEmpty) {
      setState(() {
        _imagePaths =
            existingImages.map((img) => img['file_path'] as String).toList();
      });
    }
  }

  String get _title {
    return switch (widget.recordType) {
      'INITIAL' => '증상 시작',
      'COMPLETE' => '증상 종료',
      'PROGRESS' => widget.isEditMode ? '경과 수정' : '경과 기록',
      'TREATMENT' => widget.isEditMode ? '치료기록 수정' : '치료 기록',
      _ => '기록',
    };
  }

  String get _memoHint {
    return switch (widget.recordType) {
      'INITIAL' => '증상 시작',
      'COMPLETE' => '증상 종료',
      'PROGRESS' => '(선택) 증상의 경과를 입력해주세요',
      'TREATMENT' => '(선택) 치료 내용을 입력해주세요',
      _ => '메모',
    };
  }

  double get _height {
    return switch (widget.recordType) {
      'COMPLETE' => 40.0,
      'PROGRESS' => 60.0,
      'TREATMENT' => 70.0,
      _ => 70.0,
    };
  }

  Future<void> _loadInitialTreatment() async {
    final treatments = await DatabaseService().getTreatments();
    if (treatments.isNotEmpty) {
      setState(() {
        selectedTreatment = treatments.first;
      });
    }
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return;

    setState(() {
      _isPickingImages = true;
    });

    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(images.map((image) => image.path));
        });
      }
    } finally {
      setState(() {
        _isPickingImages = false;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final (minDate, maxDate) = await _computeDateBounds();

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DateTimePickerBottomSheet(
            initialDate: _selectedDateTime,
            minDate: minDate,
            maxDate: maxDate,
          ),
    );

    if (result != null) {
      setState(() {
        _selectedDateTime = result;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void createNewHistory() async {
    try {
      if (widget.isEditMode) {
        await DatabaseService().updateHistory(
          historyId: widget.existingHistory!['history_id'],
          eventType: widget.recordType,
          recordDate: _selectedDateTime.toIso8601String(),
          memo: _memoController.text,
          treatmentId: selectedTreatment?['treatment_id'],
          treatmentName: selectedTreatment?['treatment_name'],
        );

        List<String> finalImagePaths = [];

        if (_imagePaths != null && _imagePaths.isNotEmpty) {
          for (String imagePath in _imagePaths) {
            // 이미 저장된 이미지 경로인지 확인
            if (imagePath.contains('app_flutter/images/')) {
              finalImagePaths.add(imagePath);
            } else {
              // 새로운 이미지는 저장
              final savedPath = await FileService().saveImageToAppStorage(
                imagePath,
              );
              finalImagePaths.add(savedPath);
            }
          }
        }

        // 기존 이미지 모두 삭제
        await DatabaseService().deleteAllImagesByHistoryId(
          widget.existingHistory!['history_id'],
        );

        // 최종 이미지 경로들 저장
        if (finalImagePaths.isNotEmpty) {
          await DatabaseService().saveImages(
            widget.existingHistory!['history_id'],
            finalImagePaths,
          );
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('수정되었습니다')));

        Navigator.of(context).pop(true);
      } else {
        final recordType = widget.recordType;
        final historyDate = _selectedDateTime.toIso8601String();
        final memo = _memoController.text;
        final historyId;
        final resultMessage =
            recordType == 'PROGRESS' ? '경과가 기록되었습니다' : '치료가 기록되었습니다';

        // 1. 히스토리 생성
        if (recordType == 'PROGRESS') {
          // 경과 기록
          historyId = await DatabaseService().createHistory(
            recordId: widget.recordId,
            eventType: recordType,
            recordDate: historyDate,
            memo: memo,
          );
        } else {
          // 치료 기록
          if (selectedTreatment == null || selectedTreatment!.isEmpty) return;

          final treatmentId = selectedTreatment!['treatment_id'];
          final treatmentName = selectedTreatment!['treatment_name'];

          historyId = await DatabaseService().createHistory(
            recordId: widget.recordId,
            eventType: recordType,
            recordDate: historyDate,
            memo: memo,
            treatmentId: treatmentId,
            treatmentName: treatmentName,
          );
        }

        // 이미지 저장
        if (_imagePaths != null && _imagePaths.isNotEmpty) {
          final savedImagePaths = await FileService().saveImagesToAppStorage(
            _imagePaths,
          );
          if (savedImagePaths.isNotEmpty) {
            await DatabaseService().saveImages(historyId, savedImagePaths);
          }
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(resultMessage)));

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('저장 중 오류가 발생했습니다: $e');
      Navigator.of(context).pop(false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
    }
  }

  void endRecord() async {
    try {
      final recordType = widget.recordType;
      final historyDate = _selectedDateTime.toIso8601String();
      final memo = _memoController.text;

      // record 종료
      await DatabaseService().endRecord(
        recordId: widget.recordId,
        endDate: historyDate,
      );

      // 종료 히스토리 생성
      final result = await DatabaseService().createHistory(
        recordId: widget.recordId,
        eventType: recordType,
        recordDate: historyDate,
        memo: memo,
      );

      print('result : ${result}');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('기록이 종료되었습니다')));

      Navigator.of(context).pop(true);
    } catch (e) {
      print('저장 중 오류가 발생했습니다: $e');
      Navigator.of(context).pop(false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(_height),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          DragHandle(),
          Padding(
            padding: context.paddingSM,
            child: Text(
              _title,
              style: AppTextStyle.subTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.recordType == 'TREATMENT') ...[
                    _buildTreatmentSection(),
                    SizedBox(height: context.hp(1)),
                  ],
                  _buildDateTimeSection(),
                  SizedBox(height: context.hp(1)),
                  _buildMemoSection(),
                  SizedBox(height: context.hp(1)),
                  if (widget.recordType != 'COMPLETE') ...[
                    _buildImageSection(),
                    SizedBox(height: context.hp(1)),
                  ],
                  SizedBox(height: context.hp(10)), // 버튼 공간 확보
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  void _showTreatmentBottomSheet() async {
    final result = await TreatmentBottomSheet.show(
      context,
      selectedTreatment: selectedTreatment,
    );
    if (result != null) {
      setState(() {
        selectedTreatment = result;
      });
    }
  }

  Widget _buildTreatmentSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4,
            children: [
              Text(
                '치료',
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showTreatmentBottomSheet();
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Text(
                    selectedTreatment?['treatment_name'] ?? '치료를 선택하세요',
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    LucideIcons.chevronDown,
                    size: context.xl,
                    color: AppColors.lightGrey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4,
            children: [
              Text(
                '시간',
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: _selectDateTime,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendarDays,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                  SizedBox(width: context.wp(3)),
                  Text(
                    '${_selectedDateTime.year}년 ${_selectedDateTime.month}월 ${_selectedDateTime.day}일 ${_selectedDateTime.hour}시 ${_selectedDateTime.minute.toString().padLeft(2, '0')}분',
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoSection() {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            '메모',
            style: AppTextStyle.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Flexible(
          child: TextField(
            style: AppTextStyle.body.copyWith(color: AppColors.textPrimary),
            controller: _memoController,
            decoration: InputDecoration(
              hintText: _memoHint,
              hintStyle: AppTextStyle.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                '사진',
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                _pickImages();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Icon(
                      LucideIcons.image,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    Text(
                      '사진 추가',
                      style: AppTextStyle.body.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.hp(1)),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imagePaths.length,
            padding: const EdgeInsets.only(right: 4),
            itemBuilder: (context, index) {
              final path = _imagePaths[index];
              final file = File(path);

              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 썸네일 카드
                    Container(
                      width: 85,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        child:
                            file.existsSync()
                                ? Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.lightGrey,
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 30,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  color: AppColors.lightGrey,
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 30,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                      ),
                    ),

                    Positioned(
                      top: 5,
                      right: 5,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _removeImage(index),
                          child: const Padding(
                            padding: EdgeInsets.all(6), // ← 터치영역 확대
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: context.paddingSM,
      child: Row(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '취소',
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: context.wp(4)),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (widget.recordType == 'COMPLETE') {
                  endRecord();
                } else {
                  createNewHistory();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
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
      ),
    );
  }
}
