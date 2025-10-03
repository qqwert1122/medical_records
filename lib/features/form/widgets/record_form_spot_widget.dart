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
  final VoidCallback? onChanged;

  const RecordFormSpotWidget({super.key, this.initialSpotId, this.onChanged});

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
      // spot_id로 찾기
      try {
        final spot = spots.firstWhere(
          (spot) => spot['spot_id'] == widget.initialSpotId,
        );
        if (mounted) {
          setState(() {
            selectedSpot = spot;
          });
          widget.onChanged?.call();
        }
      } catch (e) {
        // 해당 spot을 찾지 못한 경우 null 상태
        if (mounted) {
          setState(() {
            selectedSpot = null;
          });
        }
      }
    } else {
      // 추가 모드: null 상태로 시작
      if (mounted) {
        setState(() {
          selectedSpot = null;
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
          bottomLeft: Radius.circular(24.0),
          bottomRight: Radius.circular(24.0),
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
                '위치',
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
                _showSpotBottomSheet();
              },
              child: Row(
                children: [
                  Spacer(),
                  Text(
                    selectedSpot?['spot_name'] ?? '없음',
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

  void _showSpotBottomSheet() async {
    final result = await SpotBottomSheet.show(
      context,
      selectedSpot: selectedSpot,
    );
    if (result != null && mounted) {
      setState(() {
        selectedSpot = result;
      });
      widget.onChanged?.call();
    }
  }
}
