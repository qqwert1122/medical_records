import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/analysis_service.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:medical_records/widgets/drag_handle.dart';
import 'package:shimmer/shimmer.dart';

class TreatmentBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? selectedTreatment;

  const TreatmentBottomSheet({super.key, this.selectedTreatment});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? selectedTreatment,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder:
          (context) =>
              TreatmentBottomSheet(selectedTreatment: selectedTreatment),
    );
  }

  @override
  State<TreatmentBottomSheet> createState() => _TreatmentBottomSheetState();
}

class _TreatmentBottomSheetState extends State<TreatmentBottomSheet> {
  List<Map<String, dynamic>> treatmentsWithLastUsedAt = [];

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    final dbService = DatabaseService();
    final analysisService = AnalysisService();

    final base = await dbService.getTreatments();
    final lastRows = await analysisService.getTreatmentsLastUsedAt();

    final lastMap = <int, String?>{
      for (final r in lastRows)
        (r['treatment_id'] as int): r['last_used_at'] as String?,
    };

    final result = [
      for (final s in base)
        {...s, 'last_used_at': lastMap[s['treatment_id'] as int]},
    ];

    if (mounted) {
      setState(() {
        treatmentsWithLastUsedAt = result;
      });
    }
  }

  void _showTreatmentDialog({Map<String, dynamic>? treatment}) {
    String treatmentName = treatment?['treatment_name'] ?? '';

    bool isEdit = treatment != null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: AppColors.background,
                  title: Text(
                    isEdit ? '치료 수정' : '치료 추가',
                    style: AppTextStyle.title,
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('치료 이름', style: AppTextStyle.subTitle),
                      TextField(
                        controller: TextEditingController(text: treatmentName),
                        decoration: InputDecoration(
                          hintText: '이름',
                          hintStyle: AppTextStyle.hint,
                        ),
                        onChanged: (value) => treatmentName = value,
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
                        if (treatmentName.isNotEmpty) {
                          if (isEdit) {
                            await _updateTreatment(
                              treatmentId: treatment['treatment_id'],
                              name: treatmentName,
                            );
                          } else {
                            await _saveTreatment(treatmentName);
                          }
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          _loadTreatments();
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

  Future<void> _saveTreatment(String name) async {
    await DatabaseService().createTreatment(name);
  }

  Future<void> _updateTreatment({
    required int treatmentId,
    required String name,
  }) async {
    await DatabaseService().updateTreatment(
      treatmentId: treatmentId,
      name: name,
    );
  }

  Future<void> _deleteTreatment(int treatmentId) async {
    await DatabaseService().deleteTreatment(treatmentId);
    _loadTreatments();
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
                  '치료',
                  style: AppTextStyle.subTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showTreatmentDialog();
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
                treatmentsWithLastUsedAt.isEmpty
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
                          Text('저장된 치료가 없습니다', style: AppTextStyle.hint),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: treatmentsWithLastUsedAt.length,
                      itemBuilder: (context, index) {
                        final treatment = treatmentsWithLastUsedAt[index];
                        return Slidable(
                          key: ValueKey(treatment['treatment_id']),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  HapticFeedback.lightImpact();
                                  _showTreatmentDialog(treatment: treatment);
                                },
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: '수정',
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  HapticFeedback.lightImpact();
                                  _deleteTreatment(treatment['treatment_id']);
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
                                  widget.selectedTreatment?['treatment_name'] ==
                                          treatment['treatment_name']
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : null,
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    treatment['treatment_name'],
                                    style: AppTextStyle.body.copyWith(
                                      color:
                                          widget.selectedTreatment?['treatment_name'] ==
                                                  treatment['treatment_name']
                                              ? AppColors.primary
                                              : AppColors.lightGrey,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    TimeFormat.getRelativeTime(
                                      treatment['last_used_at'],
                                    ),
                                    style: AppTextStyle.caption.copyWith(
                                      color: AppColors.lightGrey,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context, treatment);
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
