import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/screens/add_record_page.dart';
import 'package:medical_records/widgets/record.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/widgets/spot_bottom_sheet.dart';

class Records extends StatefulWidget {
  const Records({super.key});

  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records> {
  String spot = '혓바닥';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 기록', style: AppTextStyle.title),
        backgroundColor: AppColors.background,
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () async {
                  final result = await SpotBottomSheet.show(context) ?? '혓바닥';
                  setState(() {
                    spot = result;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: context.xl),
                      SizedBox(width: context.wp(2)),
                      Text(spot, style: AppTextStyle.body),
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
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Record();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecordPage()),
          );
        },
        child: Icon(LucideIcons.plus, size: context.xl),
      ),
    );
  }
}
