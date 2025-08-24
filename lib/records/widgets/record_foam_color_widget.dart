import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordFoamColorWidget extends StatefulWidget {
  final Color? initialColor;

  const RecordFoamColorWidget({super.key, this.initialColor});

  @override
  State<RecordFoamColorWidget> createState() => RecordFoamColorWidgetState();
}

class RecordFoamColorWidgetState extends State<RecordFoamColorWidget> {
  late Color selectedColor;

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
    selectedColor = widget.initialColor ?? Colors.pinkAccent.shade100;
  }

  Color getSelectedColor() {
    return selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: context.wp(12),
          child: Text(
            '색상',
            style: AppTextStyle.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showColorPickerModal(context),
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPickerModal(BuildContext context) {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(
            '색상 선택',
            style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      selectedColor = color;
                    });
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
          ),
        );
      },
    );
  }
}
