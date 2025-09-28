import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/features/form/screens/record_form_page.dart';
import 'package:medical_records/features/settings/screens/setting_page.dart';
import 'package:medical_records/features/analysis/screens/analysis_page.dart';
import 'package:medical_records/features/images/screens/images_page.dart';
import 'package:medical_records/features/history/screens/history_page.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class NavigationDrawer extends StatelessWidget {
  final VoidCallback? onAddRecord;
  final VoidCallback? onNavigateToRecordsList;

  const NavigationDrawer({
    super.key,
    this.onAddRecord,
    this.onNavigateToRecordsList,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerTile(
                    context: context,
                    icon: LucideIcons.home,
                    title: '홈',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: LucideIcons.plus,
                    title: '새 기록 추가',
                    onTap: () {
                      Navigator.pop(context);
                      onAddRecord?.call();
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: LucideIcons.list,
                    title: '기록 목록',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigateToRecordsList?.call();
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: LucideIcons.clock,
                    title: '히스토리',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryPage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: LucideIcons.barChart,
                    title: '통계 분석',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AnalysisPage()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: LucideIcons.image,
                    title: '이미지',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ImagesPage()),
                      );
                    },
                  ),
                  Divider(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    height: 32,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: LucideIcons.settings,
                    title: '설정',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: AppTextStyle.subTitle.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 10,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
