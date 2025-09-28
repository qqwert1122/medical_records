import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CustomFilterChips extends StatelessWidget {
  final List<String> items;
  final String selectedItem;
  final Function(String) onItemSelected;
  final Color? color;

  const CustomFilterChips({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children:
          items.map((item) {
            final isSelected = selectedItem == item;
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (selected) {
                onItemSelected(item);
              },
              backgroundColor: AppColors.backgroundSecondary,
              selectedColor: color ?? AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              side: BorderSide.none,
              checkmarkColor: AppColors.background,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              labelPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              labelStyle: AppTextStyle.caption.copyWith(
                color:
                    isSelected ? AppColors.background : AppColors.textSecondary,
                fontSize: 11,
              ),
            );
          }).toList(),
    );
  }
}
