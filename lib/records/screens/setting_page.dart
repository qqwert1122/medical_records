import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/enum/bio_state.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/services/review_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/launcher.dart';
import 'package:medical_records/widgets/pin_code_dialog.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  static const _kSecurityEnabledKey = 'security_enabled';
  static const _kPinKey = 'pin_code';

  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool _securityEnabled = false;

  // 생명주기
  @override
  void initState() {
    super.initState();
    _loadSecurity();
  }

  Future<void> _loadSecurity() async {
    final enabled = await storage.read(key: _kSecurityEnabledKey);
    _securityEnabled = enabled == 'true';
    if (mounted) {
      setState(() {});
    }
  }

  Future<BioState> _bioState() async {
    final supported = await auth.isDeviceSupported();
    if (!supported) return BioState.unsupported;
    final types = await auth.getAvailableBiometrics();
    return types.isEmpty ? BioState.notEnrolled : BioState.enrolled;
  }

  // 생체 인증
  Future<bool> _authBiometric({
    required String reason,
    bool allowDeviceCredential = false, // disable에서 패턴/디바이스 PIN 허용하려면 true
  }) async {
    try {
      return await auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: !allowDeviceCredential,
          useErrorDialogs: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // PIN 다이얼로그
  Future<String?> _promptPinSetup() async {
    String? pin;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PinCodeDialog(
            isSetup: true,
            onSubmit: (p) {
              pin = p;
              Navigator.pop(context);
            },
          ),
    );
    return pin;
  }

  Future<bool> _promptPinVerify(String expectedPin) async {
    bool ok = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PinCodeDialog(
            isSetup: false,
            expectedPin: expectedPin, // 다이얼로그 내부에서 검증/쿨다운 관리
            onSubmit: (_) {
              ok = true;
              // 성공 시 다이얼로그 내부에서 pop
            },
          ),
    );
    return ok;
  }

  // 보안 설정 토글 저장
  Future<void> _setSecurityEnabled(bool enabled) async {
    await storage.write(
      key: _kSecurityEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  // 안내/설정 이동
  Future<bool?> _askBiometricEnroll() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.shieldCheck,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  '더 안전하게 보호해요',
                  style: AppTextStyle.subTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '얼굴/지문을 등록하면 핀 분실 걱정 없이 잠금 해제할 수 있어요.',
                  style: AppTextStyle.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(LucideIcons.scanFace),
                    label: const Text('지금 등록 (추천)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('다음에 하기', style: AppTextStyle.body),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _openSecuritySettings() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        await AppSettings.openAppSettings(
          type: AppSettingsType.lockAndPassword,
        );
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        await AppSettings.openAppSettings(type: AppSettingsType.settings);
      } else {
        await AppSettings.openAppSettings();
      }
    } catch (_) {
      try {
        await AppSettings.openAppSettings();
      } catch (_) {}
    } finally {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정에서 생체인증을 등록한 뒤 다시 시도하세요.')),
      );
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
    final ok = next ? await _enableSecurity() : await _disableSecurity();
    if (ok && mounted) setState(() => _securityEnabled = next);
  }

  Future<bool> _enableSecurity() async {
    final state = await _bioState();

    // 0) 미지원 → PIN 폴백
    if (state == BioState.unsupported) {
      final pin = await _promptPinSetup();
      if (pin == null) return false;
      await storage.write(key: _kPinKey, value: pin);
      await _setSecurityEnabled(true);
      return true;
    }

    // 1) 지원 + 미등록 → 등록 유도 or PIN 폴백
    if (state == BioState.notEnrolled) {
      final go = await _askBiometricEnroll();
      if (go == true) {
        await _openSecuritySettings();
        return false; // 설정 갔다가 다시 시도
      }
      final pin = await _promptPinSetup();
      if (pin == null) return false;
      await storage.write(key: _kPinKey, value: pin);
      await _setSecurityEnabled(true);
      return true;
    }

    // 2) 등록됨 → 생체 인증
    final ok = await _authBiometric(
      reason: '보안 기능을 활성화하려면 인증이 필요합니다',
      allowDeviceCredential: false,
    );
    if (!ok) return false;
    await _setSecurityEnabled(true);
    return true;
  }

  Future<bool> _disableSecurity() async {
    final state = await _bioState();
    final storedPin = await storage.read(key: _kPinKey);

    // 1) 등록됨 → 생체/디바이스 인증으로 해제 우선
    if (state == BioState.enrolled) {
      final ok = await _authBiometric(
        reason: '보안 기능을 해제하려면 인증이 필요합니다',
        allowDeviceCredential: true, // 패턴/디바이스 PIN 허용
      );
      if (ok) {
        await _setSecurityEnabled(false);
        await storage.delete(key: _kPinKey);
        return true;
      }
    }

    // 2) PIN 폴백
    if (storedPin != null) {
      final ok = await _promptPinVerify(storedPin);
      if (ok) {
        await _setSecurityEnabled(false);
        await storage.delete(key: _kPinKey);
        return true;
      }
    }

    // 3) 실패 안내
    await _showAlert('해제 실패', '인증에 실패했습니다.');
    return false;
  }

  Future<void> _showAlert(String title, String message) async {
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.background,
            title: Text(
              title,
              style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
            ),
            content: Text(
              message,
              style: AppTextStyle.body.copyWith(color: AppColors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
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
                  '0.0.1',
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
