import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/screens/record_foam_page.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/widgets/record.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

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
    print('최초 records load');
    _loadRecords();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isLoading) {
      print('업데이트된 records load');
      _loadRecords();
    }
  }

  @override
  void didPopNext() {
    // 다른 화면에서 돌아왔을 때만 호출
    print('화면 복귀 - records 새로고침');
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
                      ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.black,
                        ),
                      )
                      : records.isEmpty
                      ? Center(child: Text('기록이 없습니다.'))
                      : ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          return Record(
                            recordData: records[index],
                            onRecordUpdated: _loadRecords,
                          );
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
            MaterialPageRoute(builder: (context) => RecordFoamPage()),
          );
          _loadRecords();
        },
        child: Icon(LucideIcons.plus, size: context.xl),
      ),
    );
  }
}
