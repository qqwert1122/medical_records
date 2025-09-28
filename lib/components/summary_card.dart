import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/components/record_circle_avatar.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>>? avatars;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.avatars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.paddingXS,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyle.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: context.hp(2)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              avatars != null && avatars!.isNotEmpty
                  ? _buildAvatarStack()
                  : SizedBox(),
              Text(
                value,
                style: AppTextStyle.title.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    if (avatars == null || avatars!.isEmpty) {
      return SizedBox.shrink();
    }

    final displayCount = avatars!.length > 3 ? 3 : avatars!.length;
    final remainingCount = avatars!.length - displayCount;

    const double avatarSize = 25.0;
    const double overlap = 20.0;

    return SizedBox(
      width:
          avatarSize +
          (displayCount - 1) * overlap +
          (remainingCount > 0 ? 20 : 0),
      height: avatarSize,
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            final record = avatars![index];
            return Positioned(
              left: index * overlap,
              child: RecordCircleAvatar(
                name: record['symptom_name'] ?? '',
                color: record['color'] ?? '4280391935',
                size: avatarSize,
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              right: 0,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textSecondary,
                  border: Border.all(color: AppColors.background, width: 1),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
