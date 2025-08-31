import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 4,
      margin: EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
