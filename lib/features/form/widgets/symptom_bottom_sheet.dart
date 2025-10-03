import 'dart:async';
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
      isScrollControlled: true,
      builder:
          (context) => SymptomBottomSheet(selectedSymptom: selectedSymptom),
    );
  }

  @override
  State<SymptomBottomSheet> createState() => _SymptomBottomSheetState();
}

class _SymptomBottomSheetState extends State<SymptomBottomSheet> {
  List<Map<String, dynamic>> symptomsWithLastUsedAt = [];
  List<Map<String, dynamic>> filteredSymptoms = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterSymptoms(_searchController.text);
    });
  }

  void _filterSymptoms(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSymptoms = symptomsWithLastUsedAt;
      });
    } else {
      setState(() {
        filteredSymptoms =
            symptomsWithLastUsedAt
                .where(
                  (symptom) => symptom['symptom_name']
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()),
                )
                .toList();
      });
    }
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
        filteredSymptoms = result;
      });
    }
  }

  void _showSymptomDialog({Map<String, dynamic>? symptom}) {
    String symptomName = symptom?['symptom_name'] ?? '';
    bool isDuplicate = false;
    final textController = TextEditingController(text: symptomName);

    bool isEdit = symptom != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              // 중복 체크 함수
              void checkDuplicate(String name) {
                if (name.isEmpty) {
                  setDialogState(() {
                    isDuplicate = false;
                  });
                  return;
                }

                final exists = symptomsWithLastUsedAt.any((s) {
                  // 수정 모드일 때는 자기 자신은 제외
                  if (isEdit && s['symptom_id'] == symptom['symptom_id']) {
                    return false;
                  }
                  return s['symptom_name'] == name;
                });

                setDialogState(() {
                  isDuplicate = exists;
                });
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                            isEdit ? '증상 수정' : '증상 추가',
                            style: AppTextStyle.subTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                isDuplicate || symptomName.isEmpty
                                    ? null
                                    : () async {
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
                                    },
                            child: Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isDuplicate || symptomName.isEmpty
                                        ? AppColors.backgroundSecondary
                                        : AppColors.primary,
                              ),
                              child: Icon(
                                LucideIcons.check,
                                color:
                                    isDuplicate || symptomName.isEmpty
                                        ? AppColors.textSecondary
                                        : AppColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: textController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '증상 이름',
                          hintStyle: AppTextStyle.hint.copyWith(fontSize: 16),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          symptomName = value;
                          checkDuplicate(value);
                        },
                      ),
                      if (isDuplicate)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '중복된 이름입니다',
                            style: AppTextStyle.caption.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: context.hp(95),
        padding: context.paddingHorizSM,
        decoration: BoxDecoration(
          color: AppColors.surface,
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
                    '증상',
                    style: AppTextStyle.subTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showSymptomDialog();
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
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '검색',
                hintStyle: AppTextStyle.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.0),
                    topRight: Radius.circular(24.0),
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.surface),
            Expanded(
              child:
                  filteredSymptoms.isEmpty
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
                            Text(
                              _searchController.text.isEmpty
                                  ? '저장된 증상이 없습니다'
                                  : '검색 결과가 없습니다',
                              style: AppTextStyle.hint,
                            ),
                          ],
                        ),
                      )
                      : Container(
                        decoration: BoxDecoration(color: AppColors.background),
                        child: ListView.builder(
                          itemCount: filteredSymptoms.length,
                          itemBuilder: (context, index) {
                            final symptom = filteredSymptoms[index];
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
                                          ? AppColors.primary.withValues(
                                            alpha: 0.1,
                                          )
                                          : null,
                                  borderRadius: BorderRadius.circular(8.0),
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
                                                  ? AppColors.primary
                                                  : AppColors.lightGrey,
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
            ),
          ],
        ),
      ),
    );
  }
}
