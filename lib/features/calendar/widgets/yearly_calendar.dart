import 'package:flutter/material.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class YearlyCalendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime) onDaySelected;
  final Function(DateTime)? onMonthTap; // 월 클릭 시 월간 뷰로 이동

  const YearlyCalendar({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    this.onMonthTap,
  }) : super(key: key);

  @override
  State<YearlyCalendar> createState() => YearlyCalendarState();
}

class YearlyCalendarState extends State<YearlyCalendar> {
  final Map<DateTime, List<Color>> _yearlyRecords = {};
  final Map<DateTime, Color> _cachedMainColors = {}; // 색상 캐싱
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadYearlyRecords();
  }

  @override
  void didUpdateWidget(YearlyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 연도가 변경되면 데이터 다시 로드
    if (widget.focusedDay.year != oldWidget.focusedDay.year) {
      _loadYearlyRecords();
    }
  }

  Future<void> _loadYearlyRecords() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      // 현재 연도 범위
      final startOfYear = DateTime(widget.focusedDay.year, 1, 1);
      final endOfYear = DateTime(widget.focusedDay.year, 12, 31, 23, 59, 59);
      final today = DateTime.now();

      // 작년부터 시작해서 올해까지 진행되는 기록들도 포함하기 위해 조회 범위 확장
      final queryStartDate = DateTime(widget.focusedDay.year - 1, 1, 1);

      final records = await DatabaseService().getOverlappingRecords(
        startDate: queryStartDate,
        endDate: endOfYear,
      );

      if (mounted) {
        setState(() {
          _yearlyRecords.clear();
          _cachedMainColors.clear();

          for (final record
              in records.toList()
                ..sort((a, b) => a['start_date'].compareTo(b['start_date']))) {
            final startDate = DateTime.parse(record['start_date']).toLocal();
            final endDate =
                record['end_date'] != null
                    ? DateTime.parse(record['end_date']).toLocal()
                    : today; // 종료일이 없으면 오늘까지

            final colorString = record['color'] as String;
            final color = Color(int.parse(colorString));

            // 기록의 시작일과 종료일 사이의 모든 날짜에 색상 추가
            DateTime currentDate = DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            );
            final normalizedEndDate = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
            );

            while (!currentDate.isAfter(normalizedEndDate)) {
              // 현재 연도 범위 내의 날짜만 처리
              if (currentDate.year == widget.focusedDay.year) {
                final dateKey = DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                );

                if (_yearlyRecords.containsKey(dateKey)) {
                  _yearlyRecords[dateKey]!.add(color);
                } else {
                  _yearlyRecords[dateKey] = [color];
                }
              }

              currentDate = currentDate.add(Duration(days: 1));
            }
          }

          // 색상 계산을 미리 캐싱
          _precomputeMainColors();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('연간 레코드 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _precomputeMainColors() {
    for (final entry in _yearlyRecords.entries) {
      final colors = entry.value;
      if (colors.isNotEmpty) {
        final colorFrequency = <Color, int>{};
        for (var color in colors) {
          colorFrequency[color] = (colorFrequency[color] ?? 0) + 1;
        }
        _cachedMainColors[entry.key] =
            colorFrequency.entries
                .reduce((a, b) => a.value >= b.value ? a : b)
                .key;
      }
    }
  }

  void refreshData() {
    _loadYearlyRecords();
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.focusedDay.year;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('연간 캘린더 로딩 중...', style: AppTextStyle.body),
          ],
        ),
      );
    }

    // 3x4 그리드로 12개월 표시 (스크롤 없이 한눈에)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9, // 약간 세로로 긴 형태
          mainAxisSpacing: context.wp(3),
          crossAxisSpacing: context.wp(3),
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          return _buildMiniMonthCalendar(context, year, month);
        },
      ),
    );
  }

  Widget _buildMiniMonthCalendar(BuildContext context, int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7; // 0=일요일

    return GestureDetector(
      onTap: () {
        // 월 클릭 시 해당 월의 1일로 월간 뷰 이동
        final monthDate = DateTime(year, month, 1);
        widget.onMonthTap?.call(monthDate);
      },
      child: Column(
        children: [
          // 월 제목
          Text(
            '$month월',
            style: AppTextStyle.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),

          // 날짜 그리드
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: 42, // 6주 * 7일
              itemBuilder: (context, index) {
                final dayNumber = index - firstWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return SizedBox();
                }

                final currentDate = DateTime(year, month, dayNumber);
                final dateKey = DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                );

                final records = _yearlyRecords[dateKey];
                final hasRecords = records != null && records.isNotEmpty;
                final recordCount = records?.length ?? 0;

                // 레코드 개수에 따른 opacity 계산
                double opacity = 0.0;
                if (hasRecords) {
                  opacity = (recordCount * 0.3).clamp(0.3, 1.0);
                }

                // 캐시된 메인 색상 사용
                final mainColor =
                    hasRecords ? _cachedMainColors[dateKey] : null;

                return Container(
                  decoration: BoxDecoration(
                    color:
                        hasRecords
                            ? mainColor!.withValues(alpha: opacity)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
