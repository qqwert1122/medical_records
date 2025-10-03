import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/services/review_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/link_launcher.dart';
import 'package:medical_records/features/security/services/security_service.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final SecurityService _securityService = SecurityService();
  bool _securityEnabled = false;

  // 생명주기
  @override
  void initState() {
    super.initState();
    _loadSecurity();
  }

  Future<void> _loadSecurity() async {
    await _securityService.initialize();
    _securityEnabled = _securityService.securityEnabled;
    if (mounted) {
      setState(() {});
    }
  }

  // 링크 타일 공통
  Widget _buildLinkTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String url,
    required String failMessage,
  }) {
    return ListTile(
      leading: Container(
        padding: context.paddingXS,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.white, size: 16),
      ),
      title: Text(
        title,
        style: AppTextStyle.body.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: () => LinkLauncher.open(context, url, failMessage: failMessage),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: AppColors.lightGrey,
        size: 24,
      ),
    );
  }

  // 토글 처리
  Future<void> _handleToggle(bool next) async {
    if (next == _securityEnabled) return;
    final ok =
        next
            ? await _securityService.enableSecurity(context)
            : await _securityService.disableSecurity(context);
    if (ok && mounted) {
      setState(() => _securityEnabled = next);
    } else {
      // 실패 시 UI 상태 되돌리기
      if (mounted) setState(() {});
    }
  }

  // 데이터 삭제
  Future<void> _deleteAllRecords() async {
    final db = await DatabaseService().database;
    final now = DateTime.now().toIso8601String();
    await db.update('records', {'deleted_at': now});
    await db.update('histories', {'deleted_at': now});
    await db.update('images', {'deleted_at': now});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('모든 기록이 삭제되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '설정',
          style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.hp(2)),
              Padding(
                padding: context.paddingHorizSM,
                child: Text(
                  '앱 서비스',
                  style: AppTextStyle.subTitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // 기록 전체 초기화
              ListTile(
                leading: Container(
                  padding: context.paddingXS,
                  decoration: const BoxDecoration(
                    color: Colors.pinkAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.history,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  '기록 전체 초기화',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (BuildContext context) => AlertDialog(
                          backgroundColor: AppColors.background,
                          title: Text(
                            '기록 전체 초기화',
                            style: AppTextStyle.title.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          content: Text(
                            '모든 기록과 사진이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
                            style: AppTextStyle.body.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                '취소',
                                style: AppTextStyle.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
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
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );
                },
                trailing: Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.lightGrey,
                  size: 24,
                ),
              ),

              // 어플리케이션 잠금
              ListTile(
                leading: Container(
                  padding: context.paddingXS,
                  decoration: const BoxDecoration(
                    color: Colors.pinkAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.lock,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  '어플리케이션 잠금',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () => _handleToggle(!_securityEnabled),
                trailing: CupertinoSwitch(
                  value: _securityEnabled,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    _handleToggle(v);
                  },
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.backgroundSecondary,
                  thumbColor: AppColors.white,
                ),
              ),

              SizedBox(height: context.hp(2)),
              Padding(
                padding: context.paddingHorizSM,
                child: Text(
                  '지원 및 정보',
                  style: AppTextStyle.subTitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: context.paddingXS,
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.star,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  '별점 5점 남기기',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final success = await ReviewService.requestReview();
                  if (!mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('리뷰 요청을 열었어요 👍')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('앱스토어로 이동합니다.')),
                    );
                  }
                },
                trailing: Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.lightGrey,
                  size: 24,
                ),
              ),
              _buildLinkTile(
                icon: LucideIcons.bug,
                iconBg: Colors.orange,
                title: '버그 제보',
                url:
                    'https://docs.google.com/forms/d/e/1FAIpQLSetdGHfZSe55ZcjZLTQ7a5XVDILbX7vAT76W3KzromFBdb4Qg/viewform?usp=header',
                failMessage: '버그 제보 링크를 열 수 없습니다.',
              ),
              _buildLinkTile(
                icon: LucideIcons.messageSquare,
                iconBg: Colors.orange,
                title: '제안 및 문의하기',
                url:
                    'https://docs.google.com/forms/d/e/1FAIpQLSfx10IUYykyDvIxBxVb_h_Gd0Wmj2BP1vp_CA6hNxizaBQVPQ/viewform?usp=header',
                failMessage: '문의하기 링크를 열 수 없습니다.',
              ),
              _buildLinkTile(
                icon: LucideIcons.fileText,
                iconBg: Colors.orange,
                title: '크레딧',
                url:
                    'https://dour-sunday-be4.notion.site/25f7162f12b280c3bf7af24086281f6f?source=copy_link',
                failMessage: '크레딧 링크를 열 수 없습니다.',
              ),
              _buildLinkTile(
                icon: LucideIcons.fileText,
                iconBg: Colors.orange,
                title: '이용약관',
                url:
                    'https://dour-sunday-be4.notion.site/25f7162f12b2807c8534e3acec11bd29?source=copy_link',
                failMessage: '이용약관 링크를 열 수 없습니다.',
              ),
              _buildLinkTile(
                icon: LucideIcons.fileText,
                iconBg: Colors.orange,
                title: '개인정보 처리방침',
                url:
                    'https://dour-sunday-be4.notion.site/25f7162f12b28072aaf7d4112b01fba4?source=copy_link',
                failMessage: '개인정보처리방침 링크를 열 수 없습니다.',
              ),

              ListTile(
                leading: Container(
                  padding: context.paddingXS,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.hash,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  '버전',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: HapticFeedback.lightImpact,
                trailing: Text(
                  '1.0.5',
                  style: AppTextStyle.subTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              SizedBox(height: context.hp(2)),
              Padding(
                padding: context.paddingHorizSM,
                child: Text(
                  '이런 앱은 어때요?',
                  style: AppTextStyle.subTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              Padding(
                padding: context.paddingSM,
                child: GestureDetector(
                  onTap: () {
                    if (Platform.isAndroid) {
                      LinkLauncher.open(
                        context,
                        'https://play.google.com/store/apps/details?id=com.burning.timer100',
                        failMessage: '개인정보처리방침 링크를 열 수 없습니다.',
                      );
                    } else {
                      LinkLauncher.open(
                        context,
                        'https://apps.apple.com/kr/app/100-타이머/id6745899351',
                        failMessage: '개인정보처리방침 링크를 열 수 없습니다.',
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 15,
                          left: 15,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '매주 100시간 자기계발 챌린지',
                                style: AppTextStyle.subTitle.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '생산성 자기계발 타이머',
                                style: AppTextStyle.body.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Image.asset(
                            'assets/images/100timer.png',
                            width: 75,
                            height: 75,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.hp(10)),
            ],
          ),
        ),
      ),
    );
  }
}
