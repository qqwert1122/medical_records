import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class TreatmentInsightSection extends StatefulWidget {
  const TreatmentInsightSection({super.key});

  @override
  State<TreatmentInsightSection> createState() =>
      _TreatmentInsightSectionState();
}

class _TreatmentInsightSectionState extends State<TreatmentInsightSection> {
  final DatabaseService _db = DatabaseService();
  bool _loading = true;

  bool _showAllTreatments = false;

  Map<String, double> _treatRate7d = {};
  Map<String, double> _treatRate14d = {};
  Map<String, double> _treatAvgGapDays = {};
  Map<String, double> _treatAvgLastToCompleteDays = {};
  List<(String label, double rate14, int n)> _treatLeaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadTreatmentInsights();
  }

  Future<void> _loadTreatmentInsights() async {
    final events = await _db.getTreatmentEventsWithRecord();

    // label -> events
    final byLabel = <String, List<Map<String, dynamic>>>{};
    for (final e in events) {
      final label = _treatLabelOf(e);
      (byLabel[label] ??= []).add(e);
    }

    final rate7 = <String, double>{};
    final rate14 = <String, double>{};
    final avgGap = <String, double>{};
    final avgLastToDone = <String, double>{};

    // 리더보드 계산을 위해 (label -> totalEvents, rate14)
    final lb = <(String, double, int)>[];

    for (final entry in byLabel.entries) {
      final label = entry.key;
      final list = entry.value;

      // 1) 치료 후 N일 내 완료율
      int total = 0, win7 = 0, win14 = 0;

      // 2) 치료 간 평균 간격(일) — 같은 record_id 내부에서만 계산
      final gapSamples = <double>[];

      // 3) 최근 치료 → 완료까지 평균(일) — 같은 record_id 내 "해당 치료 이벤트"에서 완료까지
      final lastToDoneSamples = <double>[];

      // record_id -> events(오름차순)
      final byRecord = <int, List<Map<String, dynamic>>>{};
      for (final e in list) {
        final rid = e['record_id'] as int;
        (byRecord[rid] ??= []).add(e);
      }
      for (final rec in byRecord.entries) {
        final rid = rec.key;
        final els =
            rec.value..sort((a, b) {
              final ad = _toDate(a['record_date'])!;
              final bd = _toDate(b['record_date'])!;
              return ad.compareTo(bd);
            });

        // 간격 샘플
        for (int i = 1; i < els.length; i++) {
          final prev = _toDate(els[i - 1]['record_date']);
          final cur = _toDate(els[i]['record_date']);
          if (prev != null && cur != null) {
            gapSamples.add(_daysBetween(prev, cur));
          }
        }

        // 완료율/최근→완료 샘플
        // 해당 record의 end_date
        final end = _toDate(els.first['record_end_date']);
        for (final e in els) {
          final ed = _toDate(e['record_date']);
          if (ed == null) continue;
          total += 1;

          if (end != null && !end.isBefore(ed)) {
            final diff = _daysBetween(ed, end);
            if (diff <= 7.0) win7 += 1;
            if (diff <= 14.0) win14 += 1;

            // "최근 치료 → 완료": 이 record 내 '마지막' 치료 이벤트에서만 샘플 추가
            if (identical(e, els.last)) {
              lastToDoneSamples.add(diff);
            }
          }
        }
      }

      rate7[label] = total == 0 ? 0 : (win7 / total) * 100.0;
      rate14[label] = total == 0 ? 0 : (win14 / total) * 100.0;
      avgGap[label] =
          gapSamples.isEmpty
              ? 0
              : gapSamples.reduce((a, b) => a + b) / gapSamples.length;
      avgLastToDone[label] =
          lastToDoneSamples.isEmpty
              ? 0
              : lastToDoneSamples.reduce((a, b) => a + b) /
                  lastToDoneSamples.length;

      lb.add((label, rate14[label]!, total));
    }

    // 상태 저장
    _treatRate7d = rate7;
    _treatRate14d = rate14;
    _treatAvgGapDays = avgGap;
    _treatAvgLastToCompleteDays = avgLastToDone;

    // 14일 내 완료율 TOP5 (최소 표본 n>=3 기준)
    lb.sort((a, b) => b.$2.compareTo(a.$2));
    _treatLeaderboard = lb.where((t) => t.$3 >= 3).take(5).toList();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  double _daysBetween(DateTime a, DateTime b) => b.difference(a).inHours / 24.0;

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.tryParse(v.toString());
  }

  String _treatLabelOf(Map<String, dynamic> e) {
    final name = e['treatment_name']?.toString();
    if (name != null && name.trim().isNotEmpty) return name;
    final id = e['treatment_id'];
    return (id != null) ? '치료 #$id' : '미지정';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: CircularProgressIndicator(color: AppColors.textPrimary),
      );
    }

    if (_treatRate14d.isEmpty) {
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
            Icon(
              LucideIcons.lineChart,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '계산할 기록이 부족해요',
              style: AppTextStyle.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    String fmtPct(double v) => '${v.toStringAsFixed(0)}%';
    String fmt1(double v) => '${v.toStringAsFixed(1)}일';

    // 상위 5개(이벤트수 기준 or 완료율 기준)를 표로 표시
    final rows =
        _treatRate14d.entries.toList()..sort(
          (a, b) =>
              (_treatRate14d[b.key] ?? 0).compareTo(_treatRate14d[a.key] ?? 0),
        );
    final top =
        _showAllTreatments
            ? rows.map((e) => e.key).toList()
            : rows.take(5).map((e) => e.key).toList();
    final showMore = rows.length > 5;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.lineChart,
                color: AppColors.textPrimary,
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                '치료 인사이트',
                style: AppTextStyle.subTitle.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 리더보드 (14일 내 완료율 TOP5, n>=3만)
          if (_treatLeaderboard.isNotEmpty) ...[
            Text(
              '14일 내 치료 완료 top 5',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ..._treatLeaderboard.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.$1,
                        style: AppTextStyle.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      '14일 이내 완료율 ${fmtPct(t.$2)} / n=${t.$3}',
                      style: AppTextStyle.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 테이블 헤더
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    '치료',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    '7일 완료',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    '14일 완료',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    '치료 텀',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    '마지막 치료',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...top.map(
            (label) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        label,
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        fmtPct(_treatRate7d[label] ?? 0),
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        fmtPct(_treatRate14d[label] ?? 0),
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        fmt1(_treatAvgGapDays[label] ?? 0),
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        fmt1(_treatAvgLastToCompleteDays[label] ?? 0),
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showMore)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllTreatments = !_showAllTreatments;
                    });
                  },

                  child: Text(
                    _showAllTreatments ? '접기' : '더보기 (${rows.length - 5}개)',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: context.paddingSM,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  '참고',
                  style: AppTextStyle.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '완료율: 증상이 종료된 비율',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '7일 내 완료율: 치료 후 7일 안에 증상이 끝난 비율',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '14일 내 완료율: 치료 후 14일 안에 증상이 끝난 비율',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '치료 텀: 같은 치료를 반복한 사이 간격의 평균',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '마지막 치료: 마지막 치료 이후 완치까지 평균',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
