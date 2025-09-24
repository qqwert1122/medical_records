import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:medical_records/services/analysis_service.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:medical_records/components/drag_handle.dart';

class SymptomBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? selectedSymptom;

  const SymptomBottomSheet({super.key, this.selectedSymptom});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? selectedSymptom,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => SymptomBottomSheet(selectedSymptom: selectedSymptom),
    );
  }

  @override
  State<SymptomBottomSheet> createState() => _SymptomBottomSheetState();
}

class _SymptomBottomSheetState extends State<SymptomBottomSheet> {
  List<Map<String, dynamic>> symptomsWithLastUsedAt = [];

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    final dbService = DatabaseService();
    final analysisService = AnalysisService();

    final base = await dbService.getSymptoms();
    final lastRows = await analysisService.getSymptomsLastUsedAt();

    final lastMap = <int, String?>{
      for (final r in lastRows)
        (r['symptom_id'] as int): r['last_used_at'] as String?,
    };

    final result = [
      for (final s in base)
        {...s, 'last_used_at': lastMap[s['symptom_id'] as int]},
    ];

    if (mounted) {
      setState(() {
        symptomsWithLastUsedAt = result;
      });
    }
  }

  void _showSymptomDialog({Map<String, dynamic>? symptom}) {
    String symptomName = symptom?['symptom_name'] ?? '';
    bool isEdit = symptom != null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: AppColors.background,
                  title: Text(
                    isEdit ? '증상 수정' : '증상 추가',
                    style: AppTextStyle.title,
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('증상 이름', style: AppTextStyle.subTitle),
                      TextField(
                        controller: TextEditingController(text: symptomName),
                        decoration: InputDecoration(
                          hintText: '이름',
                          hintStyle: AppTextStyle.hint,
                        ),
                        onChanged: (value) => symptomName = value,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Text(
                        '취소',
                        style: AppTextStyle.body.copyWith(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (symptomName.isNotEmpty) {
                          if (isEdit) {
                            await _updateSymptom(
                              symptom['symptom_id'],
                              symptomName,
                            );
                          } else {
                            await _saveSymptom(symptomName);
                          }
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          _loadSymptoms();
                        }
                      },
                      child: Text(
                        isEdit ? '수정' : '저장',
                        style: AppTextStyle.body.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _saveSymptom(String name) async {
    await DatabaseService().createSymptom(name);
  }

  Future<void> _updateSymptom(int symptomId, String name) async {
    await DatabaseService().updateSymptom(symptomId, name);
  }

  Future<void> _deleteSymptom(int symptomId) async {
    await DatabaseService().deleteSpot(symptomId);
    _loadSymptoms();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(80),
      padding: context.paddingHorizSM,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DragHandle(),
          Padding(
            padding: context.paddingSM,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '증상',
                  style: AppTextStyle.subTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showSymptomDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: context.paddingXS,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.white),
                      SizedBox(width: context.wp(1)),
                      Text(
                        '추가',
                        style: AppTextStyle.body.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                symptomsWithLastUsedAt.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/empty_box.png',
                            width: context.wp(30),
                            height: context.wp(30),
                            color: AppColors.lightGrey,
                          ),
                          SizedBox(height: context.hp(2)),
                          Text('저장된 증상이 없습니다', style: AppTextStyle.hint),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: symptomsWithLastUsedAt.length,
                      itemBuilder: (context, index) {
                        final symptom = symptomsWithLastUsedAt[index];
                        return Slidable(
                          key: ValueKey(symptom['symptom_id']),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  HapticFeedback.lightImpact();
                                  _showSymptomDialog(symptom: symptom);
                                },
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: '수정',
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  HapticFeedback.lightImpact();
                                  _deleteSymptom(symptom['symptom_id']);
                                },
                                backgroundColor: AppColors.lightGrey,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: '삭제',
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  widget.selectedSymptom?['symptom_name'] ==
                                          symptom['symptom_name']
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : null,
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    symptom['symptom_name'],
                                    style: AppTextStyle.body.copyWith(
                                      color:
                                          widget.selectedSymptom?['symptom_name'] ==
                                                  symptom['symptom_name']
                                              ? Colors.pink
                                              : AppColors.lightGrey,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    TimeFormat.getRelativeTime(
                                      symptom['last_used_at'],
                                    ),
                                    style: AppTextStyle.caption.copyWith(
                                      color: AppColors.lightGrey,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context, symptom);
                              },
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
