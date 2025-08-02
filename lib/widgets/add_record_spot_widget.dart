import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/widgets/spot_bottom_sheet.dart';

class AddRecordSpotWidget extends StatefulWidget {
  const AddRecordSpotWidget({super.key});

  @override
  State<AddRecordSpotWidget> createState() => _AddRecordSpotWidgetState();
}

class _AddRecordSpotWidgetState extends State<AddRecordSpotWidget> {
  String selectedSpot = '';

  @override
  void initState() {
    super.initState();
    _loadInitialSpot();
  }

  Future<void> _loadInitialSpot() async {
    final categories = await DatabaseService().getCategories();
    if (categories.isNotEmpty) {
      setState(() {
        selectedSpot = categories.first['category_name'];
      });
    } else {
      setState(() {
        selectedSpot = '위치를 선택하세요';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('위치', style: AppTextStyle.subTitle),
        SizedBox(width: context.wp(4)),
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
                  Text(selectedSpot, style: AppTextStyle.body),
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

  void _showSpotBottomSheet() async {
    final result = await SpotBottomSheet.show(
      context,
      selectedSpot: selectedSpot,
    );
    if (result != null) {
      setState(() => selectedSpot = result);
    }
  }
}
