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
import 'package:shimmer/shimmer.dart';

class SpotBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? selectedSpot;

  const SpotBottomSheet({super.key, this.selectedSpot});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? selectedSpot,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SpotBottomSheet(selectedSpot: selectedSpot),
    );
  }

  @override
  State<SpotBottomSheet> createState() => _SpotBottomSheetState();
}

class _SpotBottomSheetState extends State<SpotBottomSheet> {
  List<Map<String, dynamic>> spotsWithLastUsedAt = [];
  List<Map<String, dynamic>> filteredSpots = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSpots();
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
      _filterSpots(_searchController.text);
    });
  }

  void _filterSpots(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSpots = spotsWithLastUsedAt;
      });
    } else {
      setState(() {
        filteredSpots =
            spotsWithLastUsedAt
                .where(
                  (spot) => spot['spot_name'].toString().toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
      });
    }
  }

  Future<void> _loadSpots() async {
    final dbService = DatabaseService();
    final analysisService = AnalysisService();

    final base = await dbService.getSpots();
    final lastRows = await analysisService.getSpotsLastUsedAt();

    final lastMap = <int, String?>{
      for (final r in lastRows)
        (r['spot_id'] as int): r['last_used_at'] as String?,
    };

    final result = [
      for (final s in base)
        {...s, 'last_used_at': lastMap[s['spot_id'] as int]},
    ];

    if (mounted) {
      setState(() {
        spotsWithLastUsedAt = result;
        filteredSpots = result;
      });
    }
  }

  void _showSpotDialog({Map<String, dynamic>? spot}) {
    String spotName = spot?['spot_name'] ?? '';
    bool isDuplicate = false;
    final textController = TextEditingController(text: spotName);

    bool isEdit = spot != null;

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

                final exists = spotsWithLastUsedAt.any((s) {
                  // 수정 모드일 때는 자기 자신은 제외
                  if (isEdit && s['spot_id'] == spot['spot_id']) {
                    return false;
                  }
                  return s['spot_name'] == name;
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
                            isEdit ? '부위 수정' : '부위 추가',
                            style: AppTextStyle.subTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                isDuplicate || spotName.isEmpty
                                    ? null
                                    : () async {
                                      if (isEdit) {
                                        await _updateSpot(
                                          spotId: spot['spot_id'],
                                          name: spotName,
                                        );
                                      } else {
                                        await _saveSpot(spotName);
                                      }
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context);
                                      _loadSpots();
                                    },
                            child: Container(
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isDuplicate || spotName.isEmpty
                                        ? AppColors.backgroundSecondary
                                        : AppColors.primary,
                              ),
                              child: Icon(
                                LucideIcons.check,
                                color:
                                    isDuplicate || spotName.isEmpty
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
                          hintText: '부위 이름',
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
                          spotName = value;
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

  Future<void> _saveSpot(String name) async {
    await DatabaseService().createSpot(name: name);
  }

  Future<void> _updateSpot({required int spotId, required String name}) async {
    await DatabaseService().updateSpot(spotId: spotId, name: name);
  }

  Future<void> _deleteSpot(int spotId) async {
    await DatabaseService().deleteSpot(spotId);
    _loadSpots();
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
                    '부위',
                    style: AppTextStyle.subTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showSpotDialog();
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
                  filteredSpots.isEmpty
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
                                  ? '저장된 부위가 없습니다'
                                  : '검색 결과가 없습니다',
                              style: AppTextStyle.hint,
                            ),
                          ],
                        ),
                      )
                      : Container(
                        decoration: BoxDecoration(color: AppColors.background),
                        child: ListView.builder(
                          itemCount: filteredSpots.length,
                          itemBuilder: (context, index) {
                            final spot = filteredSpots[index];
                            return Slidable(
                              key: ValueKey(spot['spot_id']),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      HapticFeedback.lightImpact();
                                      _showSpotDialog(spot: spot);
                                    },
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit,
                                    label: '수정',
                                  ),
                                  SlidableAction(
                                    onPressed: (context) {
                                      HapticFeedback.lightImpact();
                                      _deleteSpot(spot['spot_id']);
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
                                      widget.selectedSpot?['spot_name'] ==
                                              spot['spot_name']
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
                                        spot['spot_name'],
                                        style: AppTextStyle.body.copyWith(
                                          color:
                                              widget.selectedSpot?['spot_name'] ==
                                                      spot['spot_name']
                                                  ? AppColors.primary
                                                  : AppColors.lightGrey,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        TimeFormat.getRelativeTime(
                                          spot['last_used_at'],
                                        ),
                                        style: AppTextStyle.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context, spot);
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
