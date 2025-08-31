import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class DonutChart extends StatelessWidget {
  final String title;
  final Map<String, int> stats;
  final IconData icon;
  final Color color;
  final double chartSize; // 도넛 크기 조절용

  const DonutChart({
    super.key,
    required this.title,
    required this.stats,
    required this.icon,
    required this.color,
    this.chartSize = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text(
              '표시할 데이터가 없습니다.',
              style: AppTextStyle.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 값 내림차순 정렬 후 상위 5개
    final entries =
        stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final total = top.fold<int>(0, (p, e) => p + e.value);

    final palette = <Color>[
      color,
      Color(0xFF77BEF0),
      Color(0xFFFFCB61),
      Color(0xFFFF894F),
      Color(0xFFEA5B6F),
      Color(0xFFFF3F33),
    ];

    String pct(int v) => total == 0 ? '0%' : '${((v / total) * 100).round()}%';

    return Container(
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 16),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyle.subTitle.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // 도넛
              SizedBox(
                height: chartSize,
                width: chartSize,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: chartSize * 0.1,
                    startDegreeOffset: -90,
                    sections: [
                      for (int i = 0; i < top.length; i++)
                        PieChartSectionData(
                          value: top[i].value.toDouble(),
                          color: palette[i % palette.length],
                          title:
                              total > 0
                                  ? '${((top[i].value / total) * 100).round()}%'
                                  : '',
                          titleStyle: AppTextStyle.caption.copyWith(
                            color: AppColors.white,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 오른쪽 인덱스/범례
              Expanded(
                child: Column(
                  children: [
                    for (int i = 0; i < top.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 6),
                            // 컬러칩
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: palette[i % palette.length],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 라벨
                            Expanded(
                              child: Text(
                                top[i].key,
                                style: AppTextStyle.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            // 값/퍼센트
                            Text(
                              '${top[i].value}개 / 비중 ${pct(top[i].value)}',
                              style: AppTextStyle.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
