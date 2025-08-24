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

  const AddHistoryBottomSheet({
    Key? key,
    required this.recordId,
    required this.recordType,
    this.minDate,
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

  @override
  void initState() {
    _loadInitialTreatment();
    super.initState();
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  String get _title {
    return switch (widget.recordType) {
      'INITIAL' => '증상 시작',
      'COMPLETE' => '증상 종료',
      'PROGRESS' => '경과 기록',
      'TREATMENT' => '치료 기록',
      _ => '기록',
    };
  }

  String get _memoHint {
    return switch (widget.recordType) {
      'INITIAL' => '증상 시작',
      'COMPLETE' => '증상 종료',
      'PROGRESS' => '증상의 경과를 입력해주세요',
      'TREATMENT' => '치료 내용을 입력해주세요',
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
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DateTimePickerBottomSheet(
            initialDate: _selectedDateTime,
            minDate: widget.minDate,
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
        // 치료 count++
        await DatabaseService().updateTreatmentUsage(treatmentId);
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
      await DatabaseService().endRecord(recordId: widget.recordId);

      // 종료 히스토리 생성
      await DatabaseService().createHistory(
        recordId: widget.recordId,
        eventType: recordType,
        recordDate: historyDate,
        memo: memo,
      );

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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _title,
                style: AppTextStyle.subTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
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
          child: Text(
            '치료',
            style: AppTextStyle.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
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
          child: Text(
            '시간',
            style: AppTextStyle.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
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
          ],
        ),
        SizedBox(height: context.hp(1)),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 이미지 추가 버튼
              DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: AppColors.textSecondary,
                  strokeWidth: 1,
                  dashPattern: [8, 4],
                  radius: Radius.circular(12),
                ),
                child: GestureDetector(
                  onTap: _isPickingImages ? null : _pickImages,
                  child: SizedBox(
                    width: 90,
                    height: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.image,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                        SizedBox(height: context.hp(1)),
                        Text(
                          '사진 추가',
                          style: AppTextStyle.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 선택된 이미지들
              ..._imagePaths.asMap().entries.map((entry) {
                final index = entry.key;
                final path = entry.value;

                return Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(path),
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
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
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
