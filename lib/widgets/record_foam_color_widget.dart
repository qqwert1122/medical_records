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

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor ?? Colors.red.shade200;
  }

  Color getSelectedColor() {
    return selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('선택된 색깔', style: AppTextStyle.subTitle),
            SizedBox(width: context.wp(4)),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ],
        ),
        SizedBox(height: context.hp(2)),
        Container(
          padding: context.paddingSM,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  [
                        Colors.red.shade200,
                        Colors.red.shade400,
                        Colors.red.shade600,
                        Colors.red.shade800,
                        Colors.pink.shade50,
                        Colors.pink.shade100,
                        Colors.pink.shade200,
                        Colors.pink.shade300,
                        Colors.pink.shade400,
                        Colors.pink.shade500,
                        Colors.orange.shade200,
                        Colors.orange.shade400,
                        Colors.orange.shade600,
                        Colors.orange.shade800,
                        Colors.yellow.shade200,
                        Colors.yellow.shade400,
                        Colors.yellow.shade600,
                        Colors.yellow.shade800,
                        Colors.green.shade200,
                        Colors.green.shade400,
                        Colors.green.shade600,
                        Colors.green.shade800,
                        Colors.blue.shade200,
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                        Colors.blue.shade800,
                        Colors.indigo.shade200,
                        Colors.indigo.shade400,
                        Colors.indigo.shade600,
                        Colors.indigo.shade800,
                      ]
                      .map(
                        (color) => GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            width: selectedColor == color ? 120 : 40,
                            height: 40,
                            decoration: BoxDecoration(color: color),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
