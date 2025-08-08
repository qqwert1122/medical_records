import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
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
      builder: (context) => SpotBottomSheet(selectedSpot: selectedSpot),
    );
  }

  @override
  State<SpotBottomSheet> createState() => _SpotBottomSheetState();
}

class _SpotBottomSheetState extends State<SpotBottomSheet> {
  List<Map<String, dynamic>> spots = [];

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  Future<void> _loadSpots() async {
    final db = await DatabaseService().database;
    final result = await db.query('spots', where: 'deleted_at IS NULL');
    setState(() {
      spots = result;
    });
  }

  void _showSpotDialog({Map<String, dynamic>? spot}) {
    String spotName = spot?['spot_name'] ?? '';

    bool isEdit = spot != null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: AppColors.background,
                  title: Text(
                    isEdit ? '위치 수정' : '위치 추가',
                    style: AppTextStyle.title,
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('위치 이름', style: AppTextStyle.subTitle),
                      TextField(
                        controller: TextEditingController(text: spotName),
                        decoration: InputDecoration(
                          hintText: '이름',
                          hintStyle: AppTextStyle.hint,
                        ),
                        onChanged: (value) => spotName = value,
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
                        if (spotName.isNotEmpty) {
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
    return Container(
      height: context.hp(80),
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(32.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: context.paddingSM,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('위치', style: AppTextStyle.subTitle),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showSpotDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
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
                spots.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/empty_box.png',
                            width: context.wp(30),
                            height: context.wp(30),
                            color: AppColors.grey,
                          ),
                          SizedBox(height: context.hp(2)),
                          Text('저장된 위치가 없습니다', style: AppTextStyle.hint),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: spots.length,
                      itemBuilder: (context, index) {
                        final spot = spots[index];
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
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: '수정',
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  HapticFeedback.lightImpact();
                                  _deleteSpot(spot['spot_id']);
                                },
                                backgroundColor: Colors.grey.shade400,
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
                                      ? Colors.pink.shade200.withValues(
                                        alpha: 0.1,
                                      )
                                      : null,
                              borderRadius: BorderRadius.circular(16.0),
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
                                              ? Colors.pink
                                              : AppColors.grey,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    TimeFormat.getRelativeTime(
                                      spot['last_used_at'],
                                    ),
                                    style: AppTextStyle.caption.copyWith(
                                      color: AppColors.grey,
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
        ],
      ),
    );
  }
}
