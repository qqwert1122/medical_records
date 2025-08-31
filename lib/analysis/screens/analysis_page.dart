import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/analysis/enum/analysis_range.dart';
import 'package:medical_records/analysis/widgets/donut_chart.dart';
import 'package:medical_records/analysis/widgets/range_selector.dart';
import 'package:medical_records/analysis/widgets/summary_card.dart';
import 'package:medical_records/analysis/widgets/treatment_insight_section.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final DatabaseService _db = DatabaseService();

  // 필터 상태
  AnalysisRange _selectedRange = AnalysisRange.month;

  // 통계 데이터
  int _totalRecords = 0;
  int _activeRecords = 0;
  int _completedRecords = 0;
  double _averageDuration = 0;

  Map<String, int> _spotStats = {};
  Map<String, int> _symptomStats = {};
  Map<String, int> _treatmentStats = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final from = _rangeFrom(now, _selectedRange);

      // 1) 기간에 겹치는 레코드들만 가져오기 (DB 레벨에서 필터)
      final records =
          (from == null)
              ? await _db.getRecords()
              : await _db.getOverlappingRecords(startDate: from, endDate: now);

      // 2) 기본 통계
      _totalRecords = records.length;
      _activeRecords = records.where((r) => r['status'] == 'PROGRESS').length;
      _completedRecords =
          records.where((r) => r['status'] == 'COMPLETE').length;
      _calculateAverageDuration(records);

      // 3) 부위/증상 통계 (레코드 기반 집계)
      _spotStats = _buildCategoryStats(
        records,
        nameKey: 'spot_name',
        idKey: 'spot_id',
        fallbackPrefix: '부위',
      );
      _symptomStats = _buildCategoryStats(
        records,
        nameKey: 'symptom_name',
        idKey: 'symptom_id',
        fallbackPrefix: '증상',
      );

      // 4) 치료 통계 (히스토리 기반 집계)  <-- 여기 바뀐 부분
      final treatRows = await _db.getTreatmentStatsFromHistories(
        from: from,
        to: now,
      );
      _treatmentStats = {
        for (final r in treatRows) (r['label'] as String): (r['cnt'] as int),
      };
    } catch (e) {
      debugPrint('Analysis loading error: $e');
      _totalRecords = 0;
      _activeRecords = 0;
      _completedRecords = 0;
      _averageDuration = 0;
      _spotStats = {};
      _symptomStats = {};
      _treatmentStats = {};
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime? _rangeFrom(DateTime now, AnalysisRange range) {
    switch (range) {
      case AnalysisRange.week:
        return now.subtract(const Duration(days: 7));
      case AnalysisRange.month:
        return now.subtract(const Duration(days: 30));
      case AnalysisRange.threeMonths:
        return now.subtract(const Duration(days: 90));
      case AnalysisRange.year:
        return now.subtract(const Duration(days: 365));
      case AnalysisRange.all:
        return null;
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      // int(Timestamp)일 가능성 대비
      if (v is int) {
        return DateTime.fromMillisecondsSinceEpoch(v);
      }
      return DateTime.tryParse(v.toString());
    } catch (_) {
      return null;
    }
  }

  void _calculateAverageDuration(List<Map<String, dynamic>> records) {
    final completedRecords =
        records
            .where((r) => r['status'] == 'COMPLETE' && r['end_date'] != null)
            .toList();
    if (completedRecords.isEmpty) {
      _averageDuration = 0;
      return;
    }
    double totalDays = 0;
    for (var record in completedRecords) {
      final start = _parseDate(record['start_date']);
      final end = _parseDate(record['end_date']);
      if (start != null && end != null) {
        totalDays += end.difference(start).inDays;
      }
    }
    _averageDuration = totalDays / completedRecords.length;
  }

  Map<String, int> _buildCategoryStats(
    List<Map<String, dynamic>> records, {
    required String nameKey,
    required String idKey,
    required String fallbackPrefix,
  }) {
    final map = <String, int>{};
    for (final r in records) {
      String label;
      final name = r[nameKey];
      if (name != null && name.toString().trim().isNotEmpty) {
        label = name.toString();
      } else {
        final id = r[idKey];
        label = (id != null) ? '$fallbackPrefix #$id' : '미지정';
      }
      map.update(label, (v) => v + 1, ifAbsent: () => 1);
    }
    // 값 기준 내림차순 정렬 후 Map으로 반환
    final entries =
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '분석',
          style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          Padding(
            padding: context.paddingHorizSM,
            child: SizedBox(
              width: 140,
              child: RangeSelector(
                value: _selectedRange,
                onChanged: (v) {
                  setState(() => _selectedRange = v);
                  _loadAnalysis();
                },
              ),
            ),
          ),
        ],
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              )
              : RefreshIndicator(
                onRefresh: _loadAnalysis,
                color: AppColors.white,
                backgroundColor: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.surface),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildSummaryCards(),
                        ),

                        // 부위별 통계
                        DonutChart(
                          title: '부위별 통계',
                          stats: _spotStats,
                          icon: LucideIcons.locate,
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 10),

                        // 증상별 통계
                        DonutChart(
                          title: '증상별 통계',
                          stats: _symptomStats,
                          icon: LucideIcons.activitySquare,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 10),

                        // 치료별 통계
                        DonutChart(
                          title: '치료별 통계',
                          stats: _treatmentStats,
                          icon: LucideIcons.heart,
                          color: Colors.pinkAccent,
                        ),
                        const SizedBox(height: 10),
                        const TreatmentInsightSection(),
                        SizedBox(height: context.hp(10)),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: '전체 기록',
                value: '${_totalRecords.toString()}건',
                icon: LucideIcons.galleryVerticalEnd,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: '진행 중',
                value: '${_activeRecords.toString()}건',
                icon: LucideIcons.circleDashed,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: '완료됨',
                value: '${_completedRecords.toString()}건',
                icon: LucideIcons.checkCircle,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: '평균 기간',
                value: '${_averageDuration.toStringAsFixed(1)}일',
                icon: LucideIcons.timer,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
