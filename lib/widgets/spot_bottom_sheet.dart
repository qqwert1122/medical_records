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
  final String? selectedSpot;

  const SpotBottomSheet({super.key, this.selectedSpot});

  static Future<String?> show(BuildContext context, {String? selectedSpot}) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SpotBottomSheet(selectedSpot: selectedSpot),
    );
  }

  @override
  State<SpotBottomSheet> createState() => _SpotBottomSheetState();
}

class _SpotBottomSheetState extends State<SpotBottomSheet> {
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = await DatabaseService().database;
    final result = await db.query('categories', where: 'deleted_at IS NULL');
    setState(() {
      categories = result;
    });
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    String categoryName = category?['category_name'] ?? '';
    Color selectedColor =
        category != null
            ? Color(int.parse(category['category_color']))
            : Colors.red.shade200;
    bool isEdit = category != null;

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
                        controller: TextEditingController(text: categoryName),
                        decoration: InputDecoration(
                          hintText: '이름',
                          hintStyle: AppTextStyle.hint,
                        ),
                        onChanged: (value) => categoryName = value,
                      ),
                      SizedBox(height: context.hp(4)),
                      Text('선택된 색깔', style: AppTextStyle.subTitle),
                      SizedBox(height: context.hp(1)),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: selectedColor),
                      ),
                      SizedBox(height: context.hp(2)),
                      Text('색깔 팔레트', style: AppTextStyle.subTitle),
                      SizedBox(height: context.hp(1)),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              [
                                    Colors.red.shade200,
                                    Colors.red.shade400,
                                    Colors.red.shade600,
                                    Colors.red.shade800,
                                    Colors.pink.shade50,
                                    Colors.pink.shade100,
                                    Colors.pink.shade200,
                                    Colors.pink.shade300,
                                    Colors.pink.shade400,
                                    Colors.pink.shade500,
                                    Colors.orange.shade200,
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                    Colors.orange.shade800,
                                    Colors.yellow.shade200,
                                    Colors.yellow.shade400,
                                    Colors.yellow.shade600,
                                    Colors.yellow.shade800,
                                    Colors.green.shade200,
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                    Colors.green.shade800,
                                    Colors.blue.shade200,
                                    Colors.blue.shade400,
                                    Colors.blue.shade600,
                                    Colors.blue.shade800,
                                    Colors.indigo.shade200,
                                    Colors.indigo.shade400,
                                    Colors.indigo.shade600,
                                    Colors.indigo.shade800,
                                  ]
                                  .map(
                                    (color) => GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setDialogState(
                                          () => selectedColor = color,
                                        );
                                      },
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 150),
                                        width: selectedColor == color ? 80 : 40,
                                        height: 40,
                                        decoration: BoxDecoration(color: color),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
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
                        if (categoryName.isNotEmpty) {
                          if (isEdit) {
                            await _updateCategory(
                              category['category_id'],
                              categoryName,
                              selectedColor,
                            );
                          } else {
                            await _saveCategory(categoryName, selectedColor);
                          }
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          _loadCategories();
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

  Future<void> _saveCategory(String name, Color color) async {
    await DatabaseService().createCategory(name, color.toARGB32().toString());
  }

  Future<void> _updateCategory(int categoryId, String name, Color color) async {
    await DatabaseService().updateCategory(
      categoryId,
      name,
      color.toARGB32().toString(),
    );
  }

  Future<void> _deleteCategory(int categoryId) async {
    await DatabaseService().deleteCategory(categoryId);
    _loadCategories();
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
                    _showCategoryDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
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
                categories.isEmpty
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
                          Text('카테고리가 없습니다', style: AppTextStyle.hint),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return Slidable(
                          key: ValueKey(category['category_id']),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  HapticFeedback.lightImpact();
                                  _showCategoryDialog(category: category);
                                },
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: '수정',
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  HapticFeedback.lightImpact();
                                  _deleteCategory(category['category_id']);
                                },
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: '삭제',
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  widget.selectedSpot ==
                                          category['category_name']
                                      ? Colors.pink.shade200.withValues(
                                        alpha: 0.1,
                                      )
                                      : null,
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(category['category_color']),
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  SizedBox(width: context.wp(4)),
                                  Text(
                                    category['category_name'],
                                    style: AppTextStyle.body.copyWith(
                                      color:
                                          widget.selectedSpot ==
                                                  category['category_name']
                                              ? Colors.pink
                                              : AppColors.grey,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    TimeFormat.getRelativeTime(
                                      category['last_used_at'],
                                    ),
                                    style: AppTextStyle.caption.copyWith(
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(
                                  context,
                                  category['category_name'],
                                );
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
