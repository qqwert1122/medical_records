import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Future<void> _deleteAllRecords() async {
    final db = await DatabaseService().database;
    final now = DateTime.now().toIso8601String();

    await db.update('records', {'deleted_at': now});
    await db.update('histories', {'deleted_at': now});
    await db.update('images', {'deleted_at': now});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('모든 기록이 삭제되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정', style: AppTextStyle.title),
        backgroundColor: AppColors.background,
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: context.hp(2),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: context.paddingHorizSM,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(LucideIcons.history, color: AppColors.grey),
                  title: Container(
                    child: Text(
                      '기록 전체 초기화',
                      style: AppTextStyle.subTitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: AppColors.background,
                          title: Text('기록 전체 초기화', style: AppTextStyle.title),
                          content: Text(
                            '모든 기록과 사진이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
                            style: AppTextStyle.body,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                '취소',
                                style: AppTextStyle.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _deleteAllRecords();
                              },
                              child: Text(
                                '확인',
                                style: AppTextStyle.body.copyWith(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: context.paddingHorizSM,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(LucideIcons.scroll, color: AppColors.grey),
                  title: Text(
                    '이용약관',
                    style: AppTextStyle.subTitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {},
                ),
              ),

              Container(
                padding: context.paddingHorizSM,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(LucideIcons.scroll, color: AppColors.grey),
                  title: Text(
                    '기여',
                    style: AppTextStyle.subTitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {},
                ),
              ),
              Container(
                padding: context.paddingHorizSM,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(LucideIcons.hash, color: AppColors.grey),
                  title: Text(
                    '버전',
                    style: AppTextStyle.subTitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: HapticFeedback.lightImpact,
                  trailing: Text(
                    '0.0.1',
                    style: AppTextStyle.subTitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
