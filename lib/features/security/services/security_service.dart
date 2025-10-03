import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:medical_records/features/security/enums/bio_state.dart';
import 'package:medical_records/features/security/components/pin_code_dialog.dart';
import 'package:medical_records/styles/app_text_style.dart';

class SecurityService {
  static const _kSecurityEnabledKey = 'security_enabled';
  static const _kPinCodeKey = 'pin_code';

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _securityEnabled = false;
  bool _locked = false;
  bool _authInProgress = false;

  // Getters
  bool get securityEnabled => _securityEnabled;
  bool get locked => _locked;
  bool get authInProgress => _authInProgress;

  // Singleton pattern
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  /// 초기화 - 보안 설정 로드
  Future<void> initialize() async {
    await _reloadSecurityFlag();
  }

  /// 보안 설정 상태 다시 로드
  Future<void> _reloadSecurityFlag() async {
    final v = await _storage.read(key: _kSecurityEnabledKey);
    _securityEnabled = v == 'true';
  }

  /// 보안 부트스트랩 - 앱 시작 시 잠금 처리
  Future<void> bootstrapLock() async {
    await _reloadSecurityFlag();
    if (_securityEnabled) {
      _locked = true;
    }
  }

  /// 앱 생명주기에 따른 잠금 처리
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    if (!_securityEnabled) return;

    // 백그라운드로 가면 잠금
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_authInProgress) {
        _locked = true;
      }
      return;
    }

    if (state == AppLifecycleState.inactive) return;

    // 포그라운드로 돌아오면 다시 확인
    if (state == AppLifecycleState.resumed) {
      await _reloadSecurityFlag();
      if (!_securityEnabled) {
        _locked = false;
      }
    }
  }

  /// 인증 실행
  Future<bool> authenticate(BuildContext context) async {
    if (!_locked || _authInProgress || !_securityEnabled) {
      return true;
    }

    _authInProgress = true;

    try {
      // 생체인증 가능 여부 확인
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();

      if (!canCheck || !supported) {
        // 생체 불가 → PIN 폴백
        _authInProgress = false;
        final success = await _showPinDialog(context);
        return success;
      }

      final ok = await _auth.authenticate(
        localizedReason: '마이델로지 잠금 해제',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (ok) {
        _locked = false;
      }
      return ok;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        _authInProgress = false;
        return await _showPinDialog(context);
      }
      return false;
    } finally {
      _authInProgress = false;
    }
  }

  /// PIN 다이얼로그 표시
  Future<bool> _showPinDialog(BuildContext context) async {
    final stored = await _storage.read(key: _kPinCodeKey);
    bool success = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PinCodeDialog(
            isSetup: stored == null,
            onSubmit: (pin) async {
              if (stored == null) {
                await _storage.write(key: _kPinCodeKey, value: pin);
                _locked = false;
                success = true;
                Navigator.pop(context);
              } else if (stored == pin) {
                _locked = false;
                success = true;
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('잘못된 PIN입니다')));
              }
            },
            expectedPin: stored,
          ),
    );

    return success;
  }

  /// 생체인증 상태 확인
  Future<BioState> getBioState() async {
    final supported = await _auth.isDeviceSupported();
    if (!supported) return BioState.unsupported;
    final types = await _auth.getAvailableBiometrics();
    return types.isEmpty ? BioState.notEnrolled : BioState.enrolled;
  }

  /// 생체 인증 실행
  Future<bool> authenticateBiometric({
    required String reason,
    bool allowDeviceCredential = false,
  }) async {
    try {
      return await _auth.authenticate(
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

  /// PIN 설정 다이얼로그
  Future<String?> promptPinSetup(BuildContext context) async {
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

  /// PIN 검증 다이얼로그
  Future<bool> promptPinVerify(BuildContext context, String expectedPin) async {
    bool ok = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PinCodeDialog(
            isSetup: false,
            expectedPin: expectedPin,
            onSubmit: (_) {
              ok = true;
              Navigator.pop(context);
            },
          ),
    );
    return ok;
  }

  /// 보안 활성화
  Future<bool> enableSecurity(BuildContext context) async {
    final state = await getBioState();

    // 미지원 → PIN 폴백
    if (state == BioState.unsupported) {
      final pin = await promptPinSetup(context);
      if (pin == null) return false;
      await _storage.write(key: _kPinCodeKey, value: pin);
      await _setSecurityEnabled(true);
      return true;
    }

    // 지원 + 미등록 → 등록 유도 or PIN 폴백
    if (state == BioState.notEnrolled) {
      final go = await _askBiometricEnroll(context);
      if (go == true) {
        await _openSecuritySettings(context);
        return false; // 설정 갔다가 다시 시도
      }
      final pin = await promptPinSetup(context);
      if (pin == null) return false;
      await _storage.write(key: _kPinCodeKey, value: pin);
      await _setSecurityEnabled(true);
      return true;
    }

    // 등록됨 → 생체 인증
    final ok = await authenticateBiometric(
      reason: '보안 기능을 활성화하려면 인증이 필요합니다',
      allowDeviceCredential: false,
    );
    if (!ok) return false;
    await _setSecurityEnabled(true);
    return true;
  }

  /// 보안 비활성화
  Future<bool> disableSecurity(BuildContext context) async {
    final state = await getBioState();
    final storedPin = await _storage.read(key: _kPinCodeKey);

    // 등록됨 → 생체/디바이스 인증으로 해제 우선
    if (state == BioState.enrolled) {
      final ok = await authenticateBiometric(
        reason: '보안 기능을 해제하려면 인증이 필요합니다',
        allowDeviceCredential: true,
      );
      if (ok) {
        await _setSecurityEnabled(false);
        await _storage.delete(key: _kPinCodeKey);
        return true;
      }
    }

    // PIN 폴백
    if (storedPin != null) {
      final ok = await promptPinVerify(context, storedPin);
      if (ok) {
        await _setSecurityEnabled(false);
        await _storage.delete(key: _kPinCodeKey);
        return true;
      }
    }

    return false;
  }

  /// 보안 설정 저장
  Future<void> _setSecurityEnabled(bool enabled) async {
    await _storage.write(
      key: _kSecurityEnabledKey,
      value: enabled ? 'true' : 'false',
    );
    _securityEnabled = enabled;
  }

  /// 생체인증 등록 안내
  Future<bool?> _askBiometricEnroll(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, size: 28),
                const SizedBox(height: 10),
                Text(
                  '더 안전하게 보호해요',
                  style: AppTextStyle.subTitle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '얼굴/지문을 등록하면 핀 분실 걱정 없이 잠금 해제할 수 있어요.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.face),
                    label: const Text('지금 등록 (추천)'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('다음에 하기'),
                ),
              ],
            ),
          ),
    );
  }

  /// 보안 설정 열기
  Future<void> _openSecuritySettings(BuildContext context) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정에서 생체인증을 등록한 뒤 다시 시도하세요.')),
        );
      }
    }
  }
}
