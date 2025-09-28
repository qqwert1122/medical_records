import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/features/analysis/enum/analysis_range.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RangeSelector extends StatelessWidget {
  final AnalysisRange value;
  final ValueChanged<AnalysisRange> onChanged;

  const RangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <(String, AnalysisRange)>[
      ('오늘', AnalysisRange.today),
      ('최근 1주일', AnalysisRange.week),
      ('최근 1개월', AnalysisRange.month),
      ('최근 3개월', AnalysisRange.threeMonths),
      ('최근 1년', AnalysisRange.year),
      ('기간 선택', AnalysisRange.custom),
      ('전체', AnalysisRange.all),
    ];

    return DropdownButtonHideUnderline(
      child: DropdownButton2<AnalysisRange>(
        isExpanded: true,
        value: value,
        items: [
          for (final e in items)
            DropdownMenuItem<AnalysisRange>(
              value: e.$2,
              child: Text(
                e.$1,
                style: AppTextStyle.caption.copyWith(
                  fontSize: 14,
                  fontWeight: e.$2 == value ? FontWeight.w900 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
        onChanged: (v) {
          if (v == null) return;
          HapticFeedback.lightImpact();
          onChanged(v);
        },

        // 커스텀 버튼 표시 (calendar 아이콘 포함)
        selectedItemBuilder: (context) {
          return items.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  item.$1,
                  style: AppTextStyle.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );
          }).toList();
        },

        // 버튼(닫혀 있을 때) 스타일
        buttonStyleData: ButtonStyleData(
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: context.wp(3)),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
        ),

        // 아이콘
        iconStyleData: IconStyleData(
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),

        // 드롭다운(펼쳤을 때) 스타일
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          offset: const Offset(0, -4),
        ),

        // 메뉴 아이템 패딩
        menuItemStyleData: MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: context.wp(3), vertical: 8),
        ),
      ),
    );
  }
}
