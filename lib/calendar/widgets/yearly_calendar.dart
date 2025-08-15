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

  const YearlyCalendar({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  State<YearlyCalendar> createState() => YearlyCalendarState();
}

class YearlyCalendarState extends State<YearlyCalendar> {
  final Map<DateTime, List<Color>> _yearlyRecords = {};
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
    setState(() => _isLoading = true);

    try {
      // 1월 1일부터 12월 31일까지 조회
      final startOfYear = DateTime(widget.focusedDay.year, 1, 1);
      final endOfYear = DateTime(widget.focusedDay.year, 12, 31, 23, 59, 59);

      final records = await DatabaseService().getRecordsByDateRange(
        startDate: startOfYear,
        endDate: endOfYear,
      );

      setState(() {
        _yearlyRecords.clear();

        for (final record
            in records.toList()
              ..sort((a, b) => a['start_date'].compareTo(b['start_date']))) {
          final startDate = DateTime.parse(record['start_date']).toLocal();
          final dateKey = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );

          final colorString = record['color'] as String;
          final color = Color(int.parse(colorString));

          if (_yearlyRecords.containsKey(dateKey)) {
            _yearlyRecords[dateKey]!.add(color);
          } else {
            _yearlyRecords[dateKey] = [color];
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print('연간 레코드 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void refreshData() {
    print('refresh yearly records');
    _loadYearlyRecords();
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.focusedDay.year;

    return LayoutBuilder(
      // LayoutBuilder로 감싸기
      builder: (context, constraints) {
        final itemHeight = constraints.maxHeight / 3; // 화면 높이를 3으로 나눔

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: context.wp(2),
            right: context.wp(2),
            top: context.hp(1),
            bottom: context.hp(10),
          ),
          child: Column(
            children: List.generate(6, (rowIndex) {
              return SizedBox(
                height: itemHeight, // 고정 높이 설정
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMonthGrid(context, year, rowIndex * 2 + 1),
                    ),
                    SizedBox(width: context.wp(2)),
                    Expanded(
                      child: _buildMonthGrid(context, year, rowIndex * 2 + 2),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildMonthGrid(BuildContext context, int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Text(
          '$month월',
          style: AppTextStyle.body.copyWith(fontWeight: FontWeight.bold),
        ),
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

              final isSelected = isSameDay(widget.selectedDay, currentDate);
              final isToday = isSameDay(DateTime.now(), currentDate);

              // 레코드 개수에 따른 opacity 계산 (최대 5개까지 고려)
              double opacity = 0.0;
              if (hasRecords) {
                opacity = (recordCount * 0.2).clamp(0.2, 1.0); // 0.2 ~ 1.0
              }

              // color 결정
              Color? mainColor;
              if (hasRecords) {
                final colorFrequency = <Color, int>{};
                for (var c in records!) {
                  colorFrequency[c] = (colorFrequency[c] ?? 0) + 1;
                }
                // 빈도수 최댓값 색상
                mainColor =
                    colorFrequency.entries
                        .reduce((a, b) => a.value >= b.value ? a : b)
                        .key;
              }

              return GestureDetector(
                onTap: () => widget.onDaySelected(currentDate),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        hasRecords
                            ? mainColor!.withValues(alpha: opacity)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isSelected
                            ? Border.all(color: Colors.pinkAccent, width: 1)
                            : null,
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                isToday
                                    ? Colors.blueAccent
                                    : hasRecords
                                    ? Colors.white
                                    : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
