import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/records/widgets/spot_bottom_sheet.dart';
import 'package:medical_records/records/widgets/symptom_bottom_sheet.dart';

class RecordFoamSymptomWidget extends StatefulWidget {
  final int? initialSymptomId;

  const RecordFoamSymptomWidget({super.key, this.initialSymptomId});

  @override
  State<RecordFoamSymptomWidget> createState() =>
      RecordFoamSymptomWidgetState();
}

class RecordFoamSymptomWidgetState extends State<RecordFoamSymptomWidget> {
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
        setState(() {
          selectedSymptom = symptom;
        });
      } catch (e) {
        // 해당 symptom을 찾지 못한 경우 첫 번째 symptom 선택
        if (symptoms.isNotEmpty) {
          setState(() {
            selectedSymptom = symptoms.first;
          });
        }
      }
    } else {
      // 추가 모드: 첫 번째 symptom 선택
      if (symptoms.isNotEmpty) {
        setState(() {
          selectedSymptom = symptoms.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('증상', style: AppTextStyle.subTitle),
        SizedBox(width: context.wp(4)),
        Flexible(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showSymptomBottomSheet();
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Text(
                    selectedSymptom?['symptom_name'] ?? '증상을 선택하세요',
                    style: AppTextStyle.body,
                  ),
                  Spacer(),
                  Icon(
                    LucideIcons.chevronDown,
                    size: context.xl,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSymptomBottomSheet() async {
    final result = await SymptomBottomSheet.show(
      context,
      selectedSymptom: selectedSymptom,
    );
    if (result != null) {
      setState(() {
        selectedSymptom = result;
      });
    }
  }
}
