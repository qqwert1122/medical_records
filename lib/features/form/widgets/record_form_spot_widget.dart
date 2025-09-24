import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/features/form/widgets/spot_bottom_sheet.dart';

class RecordFormSpotWidget extends StatefulWidget {
  final int? initialSpotId;

  const RecordFormSpotWidget({super.key, this.initialSpotId});

  @override
  State<RecordFormSpotWidget> createState() => RecordFormSpotWidgetState();
}

class RecordFormSpotWidgetState extends State<RecordFormSpotWidget> {
  Map<String, dynamic>? selectedSpot;

  @override
  void initState() {
    super.initState();
    _loadInitialSpot();
  }

  Map<String, dynamic>? getSelectedSpot() {
    return selectedSpot;
  }

  Future<void> _loadInitialSpot() async {
    final spots = await DatabaseService().getSpots();

    if (widget.initialSpotId != null) {
      // 수정 모드: 특정 spot_id로 찾기
      try {
        final spot = spots.firstWhere(
          (spot) => spot['spot_id'] == widget.initialSpotId,
        );
        if (mounted) {
          setState(() {
            selectedSpot = spot;
          });
        }
      } catch (e) {
        // 해당 spot을 찾지 못한 경우 첫 번째 spot 선택
        if (spots.isNotEmpty && mounted) {
          setState(() {
            selectedSpot = spots.first;
          });
        }
      }
    } else {
      // 추가 모드: 첫 번째 spot 선택
      if (spots.isNotEmpty && mounted) {
        setState(() {
          selectedSpot = spots.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: context.wp(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4,
            children: [
              Text(
                '위치',
                style: AppTextStyle.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showSpotBottomSheet();
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
                    selectedSpot?['spot_name'] ?? '위치를 선택하세요',
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSpotBottomSheet() async {
    final result = await SpotBottomSheet.show(
      context,
      selectedSpot: selectedSpot,
    );
    if (result != null && mounted) {
      setState(() {
        selectedSpot = result;
      });
    }
  }
}
