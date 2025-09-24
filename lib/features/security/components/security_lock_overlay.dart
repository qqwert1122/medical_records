import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class SecurityLockOverlay extends StatelessWidget {
  final bool securityEnabled;
  final bool locked;
  final bool authInProgress;
  final VoidCallback onUnlock;

  const SecurityLockOverlay({
    super.key,
    required this.securityEnabled,
    required this.locked,
    required this.authInProgress,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    if (!securityEnabled || !locked) return const SizedBox.shrink();

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: AppColors.background,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.lock, size: 30, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    '잠김',
                    style: AppTextStyle.title.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '잠금을 해제하세요',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: authInProgress ? null : onUnlock,
                    label: const Text('잠금 해제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}