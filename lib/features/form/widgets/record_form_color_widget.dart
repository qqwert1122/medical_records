import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordFormColorWidget extends StatefulWidget {
  final Color? initialColor;
  final VoidCallback? onChanged;

  const RecordFormColorWidget({super.key, this.initialColor, this.onChanged});

  @override
  State<RecordFormColorWidget> createState() => RecordFormColorWidgetState();
}

class RecordFormColorWidgetState extends State<RecordFormColorWidget> {
  Color? selectedColor;

  final List<Color> colors = [
    Colors.red.shade800,
    Colors.red.shade600,
    Colors.red.shade400,
    Colors.red.shade200,
    Colors.pink.shade500,
    Colors.pink.shade400,
    Colors.pink.shade300,
    Colors.pink.shade200,
    Colors.pink.shade100,
    Colors.pink.shade50,
    Colors.pinkAccent.shade400,
    Colors.pinkAccent.shade200,
    Colors.pinkAccent.shade100,
    Colors.orange.shade800,
    Colors.orange.shade600,
    Colors.orange.shade400,
    Colors.orange.shade200,
    Colors.yellow.shade800,
    Colors.yellow.shade600,
    Colors.yellow.shade400,
    Colors.yellow.shade200,
    Colors.green.shade800,
    Colors.green.shade600,
    Colors.green.shade400,
    Colors.green.shade200,
    Colors.blue.shade800,
    Colors.blue.shade600,
    Colors.blue.shade400,
    Colors.blue.shade200,
    Colors.indigo.shade800,
    Colors.indigo.shade600,
    Colors.indigo.shade400,
    Colors.indigo.shade200,
  ];

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  Color? getSelectedColor() {
    return selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPickerModal(context),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: AppColors.background,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8,
              children: [
                Text(
                  '색상',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selectedColor ?? AppColors.surface,
                shape: BoxShape.circle,
                border:
                    selectedColor == null
                        ? Border.all(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                          width: 1,
                        )
                        : null,
              ),
              child: null,
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPickerModal(BuildContext context) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (BuildContext context) {
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
                      '색상 선택',
                      style: AppTextStyle.subTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 36),
                  ],
                ),
                SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: colors.length,
                  itemBuilder: (context, index) {
                    final color = colors[index];
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (mounted) {
                          setState(() {
                            selectedColor = color;
                          });
                          widget.onChanged?.call();
                        }
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
