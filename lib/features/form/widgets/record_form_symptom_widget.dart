import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/features/form/widgets/spot_bottom_sheet.dart';
import 'package:medical_records/features/form/widgets/symptom_bottom_sheet.dart';

class RecordFormSymptomWidget extends StatefulWidget {
  final int? initialSymptomId;
  final VoidCallback? onChanged;

  const RecordFormSymptomWidget({
    super.key,
    this.initialSymptomId,
    this.onChanged,
  });

  @override
  State<RecordFormSymptomWidget> createState() =>
      RecordFormSymptomWidgetState();
}

class RecordFormSymptomWidgetState extends State<RecordFormSymptomWidget> {
  Map<String, dynamic>? selectedSymptom;

  @override
  void initState() {
    super.initState();
    _loadInitialSymptom();
  }

  Map<String, dynamic>? getSelectedSymptom() {
    return selectedSymptom;
  }

  Future<void> _loadInitialSymptom() async {
    final symptoms = await DatabaseService().getSymptoms();

    if (widget.initialSymptomId != null) {
      // 수정 모드: 특정 symptom_id로 찾기
      try {
        final symptom = symptoms.firstWhere(
          (symptom) => symptom['symptom_id'] == widget.initialSymptomId,
        );
        if (mounted) {
          setState(() {
            selectedSymptom = symptom;
          });
          widget.onChanged?.call();
        }
      } catch (e) {
        // 해당 symptom을 찾지 못한 경우 null 상태
        if (mounted) {
          setState(() {
            selectedSymptom = null;
          });
        }
      }
    } else {
      // 추가 모드: null 상태로 시작
      if (mounted) {
        setState(() {
          selectedSymptom = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24.0),
          topLeft: Radius.circular(24.0),
        ),
        color: AppColors.background,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Text(
                '증상',
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
          SizedBox(width: 16),
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                _showSymptomBottomSheet();
              },
              child: Row(
                children: [
                  Spacer(),
                  Text(
                    selectedSymptom?['symptom_name'] ?? '없음',
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSymptomBottomSheet() async {
    final result = await SymptomBottomSheet.show(
      context,
      selectedSymptom: selectedSymptom,
    );
    if (result != null && mounted) {
      setState(() {
        selectedSymptom = result;
      });
      widget.onChanged?.call();
    }
  }
}
