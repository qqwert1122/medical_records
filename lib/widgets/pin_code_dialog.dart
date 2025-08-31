import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class PinCodeDialog extends StatefulWidget {
  final bool isSetup;
  final Function(String) onSubmit;
  final String? expectedPin;

  const PinCodeDialog({
    super.key,
    required this.isSetup,
    required this.onSubmit,
    this.expectedPin,
  });

  @override
  _PinCodeDialogState createState() => _PinCodeDialogState();
}

class _PinCodeDialogState extends State<PinCodeDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error; // 에러메시지

  static const _kPinFailCountKey = 'pin_fail_count';
  static const _kPinLockUntilKey = 'pin_lock_until_ms';
  static const int _lockoutThreshold = 5; // 5회 실패
  static const int _lockoutSeconds = 30; // 30초 잠금

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int _failCount = 0;
  DateTime? _lockUntil;
  int _remainingSecs = 0;
  Timer? _timer;

  bool get _isLocked =>
      _lockUntil != null && _lockUntil!.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadLockState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLockState() async {
    final failStr = await _storage.read(key: _kPinFailCountKey);
    _failCount = int.tryParse(failStr ?? '0') ?? 0;

    final untilStr = await _storage.read(key: _kPinLockUntilKey);
    if (untilStr != null) {
      final ms = int.tryParse(untilStr);
      if (ms != null) {
        final until = DateTime.fromMillisecondsSinceEpoch(ms);
        if (until.isAfter(DateTime.now())) {
          _lockUntil = until;
          _startCountdown();
        } else {
          await _clearLock();
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _clearLock() async {
    _lockUntil = null;
    _remainingSecs = 0;
    _failCount = 0;
    await _storage.write(key: _kPinFailCountKey, value: '0');
    await _storage.delete(key: _kPinLockUntilKey);
  }

  void _startCountdown() {
    _timer?.cancel();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_lockUntil == null) {
      _timer?.cancel();
      return;
    }
    final diff = _lockUntil!.difference(DateTime.now());
    if (diff.isNegative) {
      _timer?.cancel();
      _clearLock();
      if (mounted) setState(() => _error = null);
      return;
    }
    if (mounted) setState(() => _remainingSecs = diff.inSeconds + 1);
  }

  Future<void> _registerFail() async {
    _failCount += 1;
    await _storage.write(key: _kPinFailCountKey, value: '$_failCount');

    if (_failCount >= _lockoutThreshold) {
      _lockUntil = DateTime.now().add(const Duration(seconds: _lockoutSeconds));
      await _storage.write(
        key: _kPinLockUntilKey,
        value: _lockUntil!.millisecondsSinceEpoch.toString(),
      );
      _startCountdown();
      setState(() {
        _error = '잠금됨: $_lockoutSeconds초 후 다시 시도하세요';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    } else {
      setState(() {
        _error = '잘못된 PIN입니다 ($_failCount/$_lockoutThreshold)';
        _pin = '';
      });
    }
    HapticFeedback.mediumImpact();
  }

  Future<void> _registerSuccess(String pin) async {
    await _clearLock();
    widget.onSubmit(pin);
  }

  void _onNumberTap(String number) async {
    HapticFeedback.lightImpact();
    if (_isLocked) {
      setState(() {
        final remain =
            _remainingSecs > 0
                ? _remainingSecs
                : _lockUntil!.difference(DateTime.now()).inSeconds + 1;
        _error = '잠김: ${remain}초 후 다시 시도하세요';
      });
      return;
    }
    if (_error != null) setState(() => _error = null);

    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += number);
        if (_confirmPin.length == 4) {
          if (_confirmPin == _pin) {
            await _registerSuccess(_pin); // 설정 성공
          } else {
            setState(() {
              _error = 'PIN이 일치하지 않습니다';
              _confirmPin = '';
              _pin = '';
              _isConfirming = false;
            });
            HapticFeedback.mediumImpact();
          }
        }
      }
      return;
    }
    if (_pin.length < 4) {
      setState(() => _pin += number);
      if (_pin.length == 4) {
        if (widget.isSetup) {
          setState(() => _isConfirming = true);
        } else {
          // 해제 모드
          if (widget.expectedPin != null) {
            if (_pin == widget.expectedPin) {
              await _registerSuccess(_pin);
            } else {
              await _registerFail();
            }
          } else {
            widget.onSubmit(_pin);
          }
        }
      }
    }
  }

  void _onDelete() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentPin = _isConfirming ? _confirmPin : _pin;

    return Dialog(
      backgroundColor: AppColors.background,
      child: Container(
        padding: context.paddingSM,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.lock, size: 30, color: AppColors.primary),
            SizedBox(height: 10),
            Text(
              widget.isSetup ? (_isConfirming ? 'PIN 확인' : 'PIN 설정') : 'PIN 입력',
              style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: 10),
            Text(
              widget.isSetup
                  ? (_isConfirming ? 'PIN을 다시 입력하세요' : '4자리 숫자를 입력하세요')
                  : '잠금을 해제하세요',
              style: AppTextStyle.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _error == null ? 0 : 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _error == null ? '' : _error!,
                  style: AppTextStyle.caption.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // PIN 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        index < currentPin.length
                            ? AppColors.primary
                            : AppColors.backgroundSecondary,
                  ),
                );
              }),
            ),
            SizedBox(height: 30),

            // 숫자 패드
            SizedBox(
              width: 280,
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  for (int i = 1; i <= 9; i++) _buildNumberButton(i.toString()),
                  Container(), // 빈 공간
                  _buildNumberButton('0'),
                  _buildDeleteButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberTap(number),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            number,
            style: AppTextStyle.title.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDelete,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            LucideIcons.delete,
            color: AppColors.textSecondary,
            size: 30,
          ),
        ),
      ),
    );
  }
}
