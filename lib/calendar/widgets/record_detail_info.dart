import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/records/screens/record_foam_page.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordDetailInfo extends StatefulWidget {
  final Map<String, dynamic> record;
  final VoidCallback? onRecordUpdated;
  const RecordDetailInfo({
    super.key,
    required this.record,
    this.onRecordUpdated,
  });

  @override
  State<RecordDetailInfo> createState() => _RecordDetailInfoState();
}

class _RecordDetailInfoState extends State<RecordDetailInfo> {
  @override
  Widget build(BuildContext context) {
    final localStartDate =
        DateTime.parse(widget.record['start_date']).toLocal();
    final localCreateDate =
        DateTime.parse(widget.record['created_at']).toLocal();
    final localUpdateDate =
        DateTime.parse(widget.record['updated_at']).toLocal();

    Widget _buildInfoRow({
      required IconData icon,
      required String label,
      String? value,
      String? color,
    }) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.hp(1),
          horizontal: context.wp(2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.lightGrey),
            SizedBox(width: context.wp(4)),
            Text(
              label,
              style: AppTextStyle.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value,
                style: AppTextStyle.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            if (color != null)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(int.parse(color)),
                ),
              ),
          ],
        ),
      );
    }

    String _formatDateTime(DateTime date) {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(color: AppColors.background),
      child: Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              '상세정보',
              style: AppTextStyle.subTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: context.hp(2)),
          _buildInfoRow(
            icon: LucideIcons.palette,
            label: '색깔',
            color: widget.record['color'],
          ),
          _buildInfoRow(
            icon: LucideIcons.stethoscope,
            label: '증상',
            value: widget.record['symptom_name'],
          ),
          _buildInfoRow(
            icon: LucideIcons.mapPin,
            label: '부위',
            value: widget.record['spot_name'],
          ),
          _buildInfoRow(
            icon: LucideIcons.calendar,
            label: '기록 날짜',
            value: _formatDateTime(localStartDate),
          ),
          if (widget.record['end_date'] != null)
            _buildInfoRow(
              icon: Icons.event_available,
              label: '종료 날짜',
              value: _formatDateTime(DateTime.parse(widget.record['end_date'])),
            ),
          _buildInfoRow(
            icon: LucideIcons.calendar,
            label: '생성일',
            value: _formatDateTime(localCreateDate),
          ),
          _buildInfoRow(
            icon: LucideIcons.calendar,
            label: '최근 업데이트 날짜',
            value: _formatDateTime(localUpdateDate),
          ),
          _buildInfoRow(
            icon: LucideIcons.hash,
            label: 'No',
            value: '${widget.record['record_id']}',
          ),
          SizedBox(height: context.hp(2)),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              print('push edit');
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RecordFoamPage(
                        recordData: widget.record,
                        selectedDate: DateTime.parse(
                          widget.record['start_date'],
                        ),
                      ),
                ),
              );

              print('result');
              if (result == true) {
                widget.onRecordUpdated?.call();
                print('after  onRecordUpdated');
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, context.hp(6)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '수정하기',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
