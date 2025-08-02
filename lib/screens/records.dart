import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/screens/add_record_page.dart';
import 'package:medical_records/services/database_service.dart';
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
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final data = await DatabaseService().getRecords();
      setState(() {
        records = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

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
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : records.isEmpty
                      ? Center(child: Text('기록이 없습니다.'))
                      : ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          return Record(recordData: records[index]);
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecordPage()),
          );
          _loadRecords();
        },
        child: Icon(LucideIcons.plus, size: context.xl),
      ),
    );
  }
}
