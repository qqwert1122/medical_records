import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/components/custom_filter_chips.dart';

class YearlySimpleCalendar extends StatefulWidget {
  final DateTime currentYear;

  const YearlySimpleCalendar({super.key, required this.currentYear});

  @override
  State<YearlySimpleCalendar> createState() => _YearlySimpleCalendarState();
}

class _YearlySimpleCalendarState extends State<YearlySimpleCalendar> {
  Map<DateTime, Map<String, int>> _daySymptomCounts = {};
  List<Map<String, dynamic>> _allRecords = [];
  Set<String> _symptoms = {};
  String _selectedSymptom = '전체';
  bool _isLoading = true;

  late ScrollController _scrollController;
  late ScrollController _headerScrollController;
  List<List<DateTime?>> _weekDays = [];
  List<String> _monthLabels = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _headerScrollController = ScrollController();

    // 스크롤 동기화
    _scrollController.addListener(() {
      if (_headerScrollController.hasClients) {
        _headerScrollController.jumpTo(_scrollController.offset);
      }
    });

    _loadYearlyData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(YearlySimpleCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentYear != widget.currentYear) {
      _loadYearlyData();
    }
  }

  Future<void> _loadYearlyData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final firstDay = DateTime(widget.currentYear.year, 1, 1);
      final lastDay =
          DateTime.now().isAfter(DateTime(widget.currentYear.year, 12, 31))
              ? DateTime(widget.currentYear.year, 12, 31)
              : DateTime.now();

      final records = await DatabaseService().getOverlappingRecords(
        startDate: firstDay,
        endDate: lastDay,
      );

      _allRecords = records;
      _symptoms = records.map((r) => r['symptom_name'] as String).toSet();

      _calculateWeekDays();
      _calculateSymptomCounts();

      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToToday();
      }
    } catch (e) {
      debugPrint('연간 데이터 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateWeekDays() {
    _weekDays.clear();
    _monthLabels.clear();

    final firstDay = DateTime(widget.currentYear.year, 1, 1);
    final lastDay =
        DateTime.now().isAfter(DateTime(widget.currentYear.year, 12, 31))
            ? DateTime(widget.currentYear.year, 12, 31)
            : DateTime.now();

    // 첫 주의 시작일 (일요일 기준)
    DateTime startOfFirstWeek = firstDay.subtract(
      Duration(days: firstDay.weekday % 7),
    );

    DateTime currentWeekStart = startOfFirstWeek;
    int currentMonth = 0;

    while (currentWeekStart.isBefore(lastDay.add(Duration(days: 7)))) {
      List<DateTime?> week = [];

      for (int i = 0; i < 7; i++) {
        DateTime day = currentWeekStart.add(Duration(days: i));

        if (day.year == widget.currentYear.year && !day.isAfter(lastDay)) {
          week.add(day);

          // 월 라벨 추가 (각 월의 첫 주에만)
          if (day.month != currentMonth && day.day <= 7) {
            while (_monthLabels.length < _weekDays.length) {
              _monthLabels.add('');
            }
            _monthLabels.add('${day.month}월');
            currentMonth = day.month;
          }
        } else {
          week.add(null);
        }
      }

      if (week.any((day) => day != null)) {
        _weekDays.add(week);
      }

      currentWeekStart = currentWeekStart.add(Duration(days: 7));
    }

    // 월 라벨 길이 맞추기
    while (_monthLabels.length < _weekDays.length) {
      _monthLabels.add('');
    }
  }

  void _calculateSymptomCounts() {
    _daySymptomCounts.clear();

    for (final record in _allRecords) {
      final startDate = DateTime.parse(record['start_date']);
      final endDate =
          record['end_date'] != null
              ? DateTime.parse(record['end_date'])
              : null;
      final symptomName = record['symptom_name'] as String;

      // 연도 내의 모든 날짜에 대해 확인
      DateTime currentDate = DateTime(widget.currentYear.year, 1, 1);
      final yearEnd = DateTime(widget.currentYear.year, 12, 31);

      while (!currentDate.isAfter(yearEnd) &&
          !currentDate.isAfter(DateTime.now())) {
        final recordStartDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final recordEndDate =
            endDate != null
                ? DateTime(endDate.year, endDate.month, endDate.day)
                : null;

        final isRecordActive =
            recordStartDate.isBefore(currentDate.add(Duration(days: 1))) &&
            (recordEndDate == null ||
                recordEndDate.isAfter(currentDate.subtract(Duration(days: 1))));

        if (isRecordActive) {
          if (!_daySymptomCounts.containsKey(currentDate)) {
            _daySymptomCounts[currentDate] = {};
          }
          _daySymptomCounts[currentDate]![symptomName] =
              (_daySymptomCounts[currentDate]![symptomName] ?? 0) + 1;
        }

        currentDate = currentDate.add(Duration(days: 1));
      }
    }
  }

  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _weekDays.isNotEmpty) {
        final todayWeekIndex = _findTodayWeekIndex();
        if (todayWeekIndex != -1) {
          final scrollPosition =
              (todayWeekIndex * 17.0) - (MediaQuery.of(context).size.width / 2);
          _scrollController.animateTo(
            scrollPosition.clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            ),
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  int _findTodayWeekIndex() {
    final today = DateTime.now();
    for (int i = 0; i < _weekDays.length; i++) {
      for (final day in _weekDays[i]) {
        if (day != null &&
            day.year == today.year &&
            day.month == today.month &&
            day.day == today.day) {
          return i;
        }
      }
    }
    return -1;
  }

  Widget _buildDayCell(DateTime? day, int weekIndex, int dayIndex) {
    if (day == null) {
      return Container(width: 16, height: 16, margin: EdgeInsets.all(0.5));
    }

    final dayKey = DateTime(day.year, day.month, day.day);
    final symptomCounts = _daySymptomCounts[dayKey] ?? {};

    Color cellColor = AppColors.background;

    if (_selectedSymptom == '전체') {
      final totalCount = symptomCounts.values.fold(
        0,
        (sum, count) => sum + count,
      );
      cellColor = _getTotalColor(totalCount);
    } else if (symptomCounts.containsKey(_selectedSymptom)) {
      final count = symptomCounts[_selectedSymptom]!;
      final symptomRecord = _allRecords.firstWhere(
        (record) => record['symptom_name'] == _selectedSymptom,
        orElse: () => {'color': '4280391935'}, // 기본 색상
      );
      final baseColor = Color(int.parse(symptomRecord['color']));
      cellColor = baseColor.withValues(
        alpha: 0.2 + (count * 0.2).clamp(0.0, 0.8),
      );
    }

    return Container(
      width: 16,
      height: 16,
      margin: EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: cellColor,
      ),
    );
  }

  Color _getTotalColor(int count) {
    if (count == 0) return AppColors.surface.withValues(alpha: 0.3);
    if (count == 1) return Colors.green.withValues(alpha: 0.3);
    if (count == 2) return Colors.green.withValues(alpha: 0.5);
    if (count == 3) return Colors.green.withValues(alpha: 0.7);
    return Colors.green.withValues(alpha: 1);
  }

  Widget _buildScrollIndicator() {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        // ScrollController가 연결되지 않은 경우
        if (!_scrollController.hasClients) {
          return SizedBox(height: 4);
        }

        try {
          final maxScrollExtent = _scrollController.position.maxScrollExtent;
          final currentOffset = _scrollController.offset;

          // 스크롤할 수 없는 경우 인디케이터 숨김
          if (maxScrollExtent <= 0) {
            return SizedBox(height: 4);
          }

          final indicatorTrackWidth =
              MediaQuery.of(context).size.width - 80; // 좌우 패딩 16씩 제외
          const indicatorThumbWidth = 80.0;

          // 스크롤 진행률 계산 (0.0 ~ 1.0)
          final progress = (currentOffset / maxScrollExtent).clamp(0.0, 1.0);

          // 썸네일 위치 계산
          final thumbPosition =
              progress * (indicatorTrackWidth - indicatorThumbWidth);

          return Center(
            child: Container(
              width: indicatorTrackWidth,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: thumbPosition,
                    child: Container(
                      width: indicatorThumbWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          // position에 접근할 수 없는 경우
          return SizedBox(height: 4);
        }
      },
    );
  }

  Widget _buildSymptomChips() {
    final allSymptoms = ['전체', ..._symptoms.toList()..sort()];

    return CustomFilterChips(
      items: allSymptoms,
      selectedItem: _selectedSymptom,
      onItemSelected: (item) {
        setState(() {
          _selectedSymptom = item;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // 월 헤더 (가로)
                SizedBox(
                  height: 20,
                  child: SingleChildScrollView(
                    controller: _headerScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: 30), // 요일 라벨 공간
                        ..._weekDays.asMap().entries.map((entry) {
                          final weekIndex = entry.key;
                          final monthLabel =
                              weekIndex < _monthLabels.length
                                  ? _monthLabels[weekIndex]
                                  : '';

                          return Container(
                            width: 17,
                            height: 20,
                            alignment: Alignment.center,
                            child:
                                monthLabel.isNotEmpty
                                    ? Text(
                                      monthLabel,
                                      style: AppTextStyle.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    )
                                    : null,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4),
                // 스크롤 가능한 캘린더 (행: 요일, 열: 주차)
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      // 요일 라벨 (고정)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:
                            weekdays
                                .map(
                                  (day) => Container(
                                    width: 30,
                                    height: 17,
                                    alignment: Alignment.center,
                                    child: Text(
                                      day,
                                      style: AppTextStyle.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      // 스크롤 가능한 캘린더 그리드
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                _weekDays.asMap().entries.map((entry) {
                                  final weekIndex = entry.key;
                                  final week = entry.value;

                                  return Column(
                                    children:
                                        week.asMap().entries.map((dayEntry) {
                                          final dayIndex = dayEntry.key;
                                          final day = dayEntry.value;
                                          return _buildDayCell(
                                            day,
                                            weekIndex,
                                            dayIndex,
                                          );
                                        }).toList(),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                _buildScrollIndicator(),
              ],
            ),
          ),

          // 스크롤 인디케이터
          SizedBox(height: 8),

          _buildSymptomChips(),
        ],
      ),
    );
  }
}
