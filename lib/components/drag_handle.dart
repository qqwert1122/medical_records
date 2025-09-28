import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';

class DragHandle extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const DragHandle({Key? key, this.width, this.height, this.color, this.margin})
    : super(key: key);

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
