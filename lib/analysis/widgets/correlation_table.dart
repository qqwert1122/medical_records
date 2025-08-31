import 'dart:math' as math;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/analysis_service.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CorrelationTable extends StatefulWidget {
  const CorrelationTable({super.key});

  @override
  State<CorrelationTable> createState() => _CorrelationTableState();
}

class _CorrelationTableState extends State<CorrelationTable> {
  final _db = DatabaseService();

  // 선택 상태 (null = 전체)
  int? _selectedSymptomId;
  int? _selectedSpotId;

  bool _loading = true;

  // 드롭다운 데이터
  late List<Map<String, dynamic>> _symptoms = [];
  late List<Map<String, dynamic>> _spots = [];

  // 집계 데이터
  late Map<(int, int), int> _cooc = {}; // (symId, spotId) -> a
  late Map<int, int> _symTotals = {}; // symId -> a+b
  late Map<int, int> _spotTotals = {}; // spotId -> a+c
  int _N = 0;

  // 표시용 결과
  late List<_CorrRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      if (!mounted) return;

      final analysis = AnalysisService();

      // 드롭다운용 마스터
      final symptoms = await analysis.getSymptomsForPicker();
      final spots = await analysis.getSpotsForPicker();

      // φ 계산용 베이스 (a, a+b, a+c, N)
      final base = await analysis.buildSymptomSpotCounts();

      setState(() {
        _symptoms = symptoms;
        _spots = spots;
        _cooc = base.cooc; // Map<(int,int), int>
        _symTotals = base.symTotals; // Map<int, int>
        _spotTotals = base.spotTotals; // Map<int, int>
        _N = base.N; // int
      });

      _recompute(); // 초기(전체) 결과 산출
    } catch (e) {
      if (!mounted) return;
      debugPrint('Correlation load error: $e');
      setState(() {
        _symptoms = [];
        _spots = [];
        _cooc = {};
        _symTotals = {};
        _spotTotals = {};
        _N = 0;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recompute() {
    final rows = <_CorrRow>[];

    // 대상 쌍 리스트
    Iterable<Map<String, dynamic>> symList = _symptoms;
    Iterable<Map<String, dynamic>> spotList = _spots;
    if (_selectedSymptomId != null) {
      symList = _symptoms.where((s) => s['symptom_id'] == _selectedSymptomId);
    }
    if (_selectedSpotId != null) {
      spotList = _spots.where((p) => p['spot_id'] == _selectedSpotId);
    }

    final N = _N; // 지역 변수로 고정

    for (final s in symList) {
      final sid = s['symptom_id'] as int;
      final sname = s['symptom_name'] as String;

      for (final p in spotList) {
        final pid = p['spot_id'] as int;
        final pname = p['spot_name'] as String;

        // 2x2 셀
        final a = _cooc[(sid, pid)] ?? 0;
        final ab = _symTotals[sid] ?? 0;
        final ac = _spotTotals[pid] ?? 0;
        final b = ab - a;
        final c = ac - a;
        final d = N - a - b - c;

        // φ
        final denom = (ab) * (N - ab) * (ac) * (N - ac);
        double phi = 0.0;
        if (N > 0 && denom > 0) {
          phi = ((a * d) - (b * c)) / math.sqrt(denom.toDouble());
        }

        // 95% CI (Fisher z)
        double ciL = double.nan, ciH = double.nan;
        if (N > 3 && phi.abs() < 0.999) {
          final z = 0.5 * math.log((1 + phi) / (1 - phi)); // atanh(phi)
          final se = 1 / math.sqrt((N - 3).toDouble());
          ciL = _tanh(z - 1.96 * se);
          ciH = _tanh(z + 1.96 * se);
        }

        rows.add(
          _CorrRow(
            symptomName: sname,
            spotName: pname,
            phi: phi,
            ciLow: ciL,
            ciHigh: ciH,
            a: a,
            b: b,
            c: c,
            d: d,
          ),
        );
      }
    }

    // 정렬: |phi| ↓, 동률이면 phi ↓, 그 다음 라벨
    rows.sort((x, y) {
      final d = y.absPhi.compareTo(x.absPhi);
      if (d != 0) return d;
      final d2 = y.phi.compareTo(x.phi);
      if (d2 != 0) return d2;
      return (x.symptomName + x.spotName).compareTo(y.symptomName + y.spotName);
    });

    setState(() => _rows = rows);
  }

  double _tanh(double x) {
    if (x > 20) return 1.0;
    if (x < -20) return -1.0;
    final e2x = math.exp(2 * x);
    return (e2x - 1) / (e2x + 1);
  }

  void _resetFilters() {
    setState(() {
      _selectedSymptomId = null;
      _selectedSpotId = null;
    });
    _recompute();
  }

  // 신뢰도 계산
  bool _expectedOk(int n, int ab, int ac) {
    if (n <= 0) return false;
    final eA = (ab * ac) / n;
    final eB = (ab * (n - ac)) / n;
    final eC = ((n - ab) * ac) / n;
    final eD = ((n - ab) * (n - ac)) / n;
    return [eA, eB, eC, eD].every((v) => v >= 5);
  }

  String _reliabilityLabel(_CorrRow r) {
    // 최소 표본/희소셀/CI 유무 체크
    if (!r.hasCI || r.a < 10 || !_expectedOk(r.n, r.ab, r.ac)) return '낮음';

    // CI 폭과 표본으로 단계 나눔 (경험적 임계값)
    if (r.ciWidth <= 0.30 && r.n >= 100) return '높음';
    if (r.ciWidth <= 0.45 && r.n >= 50) return '중간';
    return '낮음';
  }

  Color _reliabilityColor(String label) {
    switch (label) {
      case '높음':
        return Colors.green;
      case '중간':
        return Colors.amber;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAll(),
      color: AppColors.white,
      backgroundColor: AppColors.primary,
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                    '증상-부위 상관관계',
                    style: AppTextStyle.subTitle.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFilters(context),
              const SizedBox(height: 10),
              _buildTable(context),
              const SizedBox(height: 10),
              _buildLegend(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10,
      children: [
        _Picker<int>(
          label: '증상',
          value: _selectedSymptomId,
          items: [
            for (final s in _symptoms)
              DropdownMenuItem<int>(
                value: s['symptom_id'] as int,
                child: Text(
                  s['symptom_name'] as String,
                  style: AppTextStyle.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
          valueLabel: (id) {
            final idx = _symptoms.indexWhere((e) => e['symptom_id'] == id);
            return idx == -1
                ? '전체'
                : (_symptoms[idx]['symptom_name'] as String);
          },
          onChanged: (v) {
            HapticFeedback.lightImpact();
            setState(() => _selectedSymptomId = v);
            _recompute();
          },
        ),

        _Picker<int>(
          label: '부위',
          value: _selectedSpotId,
          items: [
            for (final p in _spots)
              DropdownMenuItem<int>(
                value: p['spot_id'] as int,
                child: Text(
                  p['spot_name'] as String,
                  style: AppTextStyle.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
          valueLabel: (id) {
            final idx = _spots.indexWhere((e) => e['spot_id'] == id);
            return idx == -1 ? '전체' : (_spots[idx]['spot_name'] as String);
          },
          onChanged: (v) {
            HapticFeedback.lightImpact();
            setState(() => _selectedSpotId = v);
            _recompute();
          },
        ),

        // 필터 초기화 버튼
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _resetFilters();
          },
          child: Container(
            height: 36,
            width: 36,
            padding: context.paddingXS,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: Center(
              child: Icon(
                LucideIcons.filterX,
                size: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context) {
    return Container(
      padding: context.paddingSM,
      child: Column(
        children: [
          // 테이블 헤더
          Row(
            children: [
              _th('순위', flex: 2),
              _th('증상명', flex: 7),
              _th('부위명', flex: 7),
              _th('상관계수', flex: 4, alignRight: true),
              _th('신뢰도', flex: 4, alignRight: true),
            ],
          ),
          const SizedBox(height: 6),
          // 바디
          ...List.generate(_rows.length, (i) {
            final r = _rows[i];
            final rank = i + 1;

            final rel = _reliabilityLabel(r);
            final relColor = _reliabilityColor(rel);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _td('$rank', flex: 2, secondary: true),
                  _td(r.symptomName, flex: 7),
                  _td(r.spotName, flex: 7),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        r.phi.toStringAsFixed(3),
                        style: AppTextStyle.caption.copyWith(
                          color:
                              (r.phi >= 0.4)
                                  ? Colors.blueAccent
                                  : (r.phi <= -0.4)
                                  ? Colors.redAccent
                                  : AppColors.textSecondary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        rel,
                        style: AppTextStyle.caption.copyWith(
                          color: relColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: AppTextStyle.caption.copyWith(color: AppColors.textSecondary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              '상관계수는 이렇게 참고하세요',
              style: AppTextStyle.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '+ 값 : 함께 나타나는 경향이 있음',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '+ 값 : 함께 나타나지 않는 경향이 있음',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '값이 0 ~ 0.19는 상관관계가 매우 약함',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '값이 0.20 ~ 0.39는 상관관계가 약함',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '값이 0.40 ~ 0.59는 상관관계가 보통',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '값이 0.60 ~ 0.79는 상관관계가 강함',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '값이 0.80 ~ 1.0은 상관관계가 매우 강함',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '표본수가 증가하면 신뢰도가 증가',
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
    );
  }

  // 헤더/셀 헬퍼
  Widget _th(String t, {int flex = 1, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          t,
          style: AppTextStyle.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _td(String t, {int flex = 1, bool secondary = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.caption.copyWith(
          color: secondary ? AppColors.textSecondary : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// 공통 드롭다운(언더라인 제거 + 앱 스타일)
class _Picker<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  // 👇 추가: 선택된 value를 화면에 표시할 문자로 변환
  final String Function(T value)? valueLabel;

  const _Picker({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value != null;
    final selectedText =
        (isSelected && valueLabel != null) ? valueLabel!(value as T) : '전체';

    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: false,
        value: value,
        customButton: Container(
          height: 36,
          padding: context.paddingHorizSM,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyle.caption.copyWith(
                  fontSize: 14,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                selectedText,
                style: AppTextStyle.caption.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 10),
              Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ],
          ),
        ),
        items: items,
        onChanged: onChanged,
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, -4),
          padding: const EdgeInsets.symmetric(vertical: 6),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

class _CorrRow {
  final String symptomName;
  final String spotName;
  final double phi;

  // 신뢰도 계산용(이미 _recompute에서 갖고 있는 값 저장)
  final double ciLow;
  final double ciHigh;
  final int a, b, c, d; // 2x2 셀

  double get absPhi => phi.abs();
  int get n => a + b + c + d;
  int get ab => a + b;
  int get ac => a + c;
  bool get hasCI => !(ciLow.isNaN || ciHigh.isNaN);
  double get ciWidth => hasCI ? (ciHigh - ciLow).abs() : double.infinity;

  _CorrRow({
    required this.symptomName,
    required this.spotName,
    required this.phi,
    required this.ciLow,
    required this.ciHigh,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
  });
}
