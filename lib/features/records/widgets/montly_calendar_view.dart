import 'package:flutter/material.dart';
import 'package:medical_records/features/calendar/widgets/calendar_header_widget.dart';
import 'package:medical_records/features/calendar/widgets/month_picker_bottom_sheet.dart';
import 'package:medical_records/features/calendar/widgets/montly_calendar.dart';
import 'package:medical_records/features/calendar/widgets/calendar_bottom_sheet.dart';
import 'package:medical_records/features/calendar/widgets/weekly_record_overlay.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';

class MontlyCalendarView extends StatefulWidget {
  final Function(double)? onBottomSheetHeightChanged;
  final Function(int)? onBottomSheetPageChanged;
  final DateTime? initialFocusedMonth;

  const MontlyCalendarView({
    super.key,
    this.onBottomSheetHeightChanged,
    this.onBottomSheetPageChanged,
    this.initialFocusedMonth,
  });

  @override
  State<MontlyCalendarView> createState() => _MontlyCalendarViewState();
}

class _MontlyCalendarViewState extends State<MontlyCalendarView>
    with TickerProviderStateMixin {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  double _bottomSheetHeight = 0;
  final Map<DateTime, List<Color>> _dayRecords = {};
  final Map<DateTime, Map<int, RecordInfo>> _weekRecordSlots = {};
  final Map<String, String> _recordTitles = {};
  Map<String, DateTime> _recordStartDates = {};
  Map<String, DateTime> _recordEndDates = {};

  // 바텀 네비게이션 애니메이션 컨트롤러
  late AnimationController _navAnimationController;
  late Animation<double> _navAnimation;

  // CalendarBottomSheet에 전달할 콜백을 위한 GlobalKey
  final GlobalKey<CalendarBottomSheetState> _bottomSheetKey = GlobalKey();

  int _currentBottomSheetPage = 0;

  // rebuild를 위한 버젼 관리
  int _dataVersion = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedMonth ?? DateTime.now();
    _selectedDay = widget.initialFocusedMonth ?? DateTime.now();
    _loadRecords();

    // 바텀 네비게이션 애니메이션 초기화
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _navAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0, // 네비게이션 바를 아래로 100px 이동
    ).animate(
      CurvedAnimation(parent: _navAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MontlyCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFocusedMonth != widget.initialFocusedMonth &&
        widget.initialFocusedMonth != null) {
      setState(() {
        _focusedDay = widget.initialFocusedMonth!;
        _selectedDay = widget.initialFocusedMonth!;
      });
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    if (!mounted) return;
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final startOfWeek = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    final endOfWeek = lastDay.add(Duration(days: 6 - (lastDay.weekday % 7)));

    final records = await DatabaseService().getOverlappingRecords(
      startDate: startOfWeek,
      endDate: endOfWeek,
    );

    if (mounted) {
      setState(() {
        _dayRecords.clear();
        _weekRecordSlots.clear();
        _recordTitles.clear();

        // record_id별 시작/종료 날짜 추적
        Map<String, DateTime> recordStartDates = {};
        Map<String, DateTime> recordEndDates = {};
        Map<DateTime, List<MapEntry<String, Color>>> dailyActiveRecords = {};

        for (final record
            in records.toList()
              ..sort((a, b) => a['start_date'].compareTo(b['start_date']))) {
          final startDate = DateTime.parse(record['start_date']).toLocal();
          final today = DateTime.now();
          final endDate =
              record['end_date'] != null
                  ? DateTime.parse(record['end_date']).toLocal()
                  : today.isAfter(endOfWeek)
                  ? endOfWeek
                  : today;

          final color = Color(int.parse(record['color'] as String));
          final recordId = record['record_id'].toString();

          // 레코드 타이틀 저장
          _recordTitles[recordId] = record['symptom_name'] ?? '';

          final displayStart =
              startDate.isBefore(startOfWeek) ? startOfWeek : startDate;
          final displayEnd = endDate.isAfter(endOfWeek) ? endOfWeek : endDate;

          final normalizedStart = DateTime(
            displayStart.year,
            displayStart.month,
            displayStart.day,
          );
          final normalizedEnd = DateTime(
            displayEnd.year,
            displayEnd.month,
            displayEnd.day,
          );

          // 시작/종료 날짜 저장
          recordStartDates[recordId] = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          recordEndDates[recordId] = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
          );

          for (
            DateTime date = normalizedStart;
            !date.isAfter(normalizedEnd);
            date = date.add(Duration(days: 1))
          ) {
            final dateKey = DateTime(date.year, date.month, date.day);

            if (_dayRecords.containsKey(dateKey)) {
              _dayRecords[dateKey]!.add(color);
            } else {
              _dayRecords[dateKey] = [color];
            }

            if (!dailyActiveRecords.containsKey(dateKey)) {
              dailyActiveRecords[dateKey] = [];
            }
            dailyActiveRecords[dateKey]!.add(MapEntry(recordId, color));
          }
        }

        Map<String, Map<String, int>> weekRecordSlots = {};

        for (final entry in dailyActiveRecords.entries) {
          final date = entry.key;
          final weekKey = _getWeekKey(date);

          if (!weekRecordSlots.containsKey(weekKey)) {
            weekRecordSlots[weekKey] = {};
          }

          for (final record in entry.value) {
            final recordId = record.key;
            final color = record.value;

            int slot;
            if (weekRecordSlots[weekKey]!.containsKey(recordId)) {
              slot = weekRecordSlots[weekKey]![recordId]!;
            } else {
              final usedSlots =
                  entry.value
                      .where(
                        (r) => weekRecordSlots[weekKey]!.containsKey(r.key),
                      )
                      .map((r) => weekRecordSlots[weekKey]![r.key]!)
                      .toSet();

              slot = 0;
              while (usedSlots.contains(slot)) {
                slot++;
              }
              weekRecordSlots[weekKey]![recordId] = slot;
            }

            if (!_weekRecordSlots.containsKey(date)) {
              _weekRecordSlots[date] = {};
            }

            _weekRecordSlots[date]![slot] = RecordInfo(
              recordId: recordId,
              title: _recordTitles[recordId] ?? '',
              color: color,
            );
          }
        }

        // 시작/종료 날짜 정보도 함께 저장
        _recordStartDates = recordStartDates;
        _recordEndDates = recordEndDates;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getDayRecords(DateTime? day) async {
    if (day == null) return [];

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay
        .add(Duration(days: 1))
        .subtract(Duration(microseconds: 1));

    return await DatabaseService().getOverlappingRecords(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  String _getWeekKey(DateTime date) {
    final weekday = date.weekday % 7;
    final sunday = date.subtract(Duration(days: weekday));
    return '${sunday.year}-${sunday.month}-${sunday.day}';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _bottomSheetHeight = 0.5;
        _currentBottomSheetPage = 0;
      });
      _updateNavigationAnimation(0.5);
    }
    widget.onBottomSheetHeightChanged?.call(0.5);
    _loadRecords();
  }

  // 바텀 시트 높이에 따른 네비게이션 애니메이션 업데이트
  void _updateNavigationAnimation(double bottomSheetHeight) {
    if (bottomSheetHeight > 0 && !_navAnimationController.isAnimating) {
      _navAnimationController.forward();
    } else if (bottomSheetHeight == 0 && !_navAnimationController.isAnimating) {
      _navAnimationController.reverse();
    }
  }

  void _showMonthPicker({bool isMonthlyView = true}) async {
    HapticFeedback.lightImpact();
    final selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MonthPickerBottomSheet(
            initialDate: _focusedDay,
            isMonthlyView: isMonthlyView,
          ),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _focusedDay = selectedDate;
      });
    }
  }

  Future<void> _onDataChanged() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await _loadRecords();
      if (mounted) {
        setState(() {
          _dataVersion++;
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  bool _isFutureDay(DateTime? d) {
    if (d == null) return false;
    final s = DateTime(d.year, d.month, d.day);
    final now = DateTime.now();
    final t = DateTime(now.year, now.month, now.day);
    return s.isAfter(t); // 내일 이상만 true
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            CalendarHeaderWidget(
              isMonthlyView: true,
              focusedDay: _focusedDay,
              onDateTap: () => _showMonthPicker(isMonthlyView: true),
            ),

            // 달력
            Expanded(
              child: MonthlyCalendar(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                calendarFormat: _calendarFormat,
                dayRecords: _dayRecords,
                weekRecordSlots: _weekRecordSlots,
                recordTitles: _recordTitles,
                recordStartDates: _recordStartDates,
                recordEndDates: _recordEndDates,
                bottomSheetHeight: _bottomSheetHeight,
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  HapticFeedback.lightImpact();
                  if (mounted) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  }
                  _loadRecords();
                },
                onHeightChanged: (factor) {
                  if (mounted) {
                    setState(() {
                      _bottomSheetHeight = factor;
                      widget.onBottomSheetHeightChanged?.call(factor);
                    });
                  }
                },
              ),
            ),
          ],
        ),

        // Bottom Sheet
        CalendarBottomSheet(
          key: _bottomSheetKey,
          bottomSheetHeight: _bottomSheetHeight,
          selectedDay: _selectedDay,
          selectedDayRecordsFetcher: () => _getDayRecords(_selectedDay),
          onHeightChanged: (newHeight) {
            if (mounted) {
              setState(() {
                _bottomSheetHeight = newHeight;
                if (newHeight == 0) {
                  _currentBottomSheetPage = 0;
                }
                widget.onBottomSheetHeightChanged?.call(newHeight);
              });
              _updateNavigationAnimation(newHeight);
            }
          },
          onDateChanged: (newDate) {
            if (mounted) {
              setState(() {
                _selectedDay = newDate;
                _focusedDay = newDate;
              });
            }
          },
          onDataChanged: _onDataChanged,
          onPageChanged: (pageIndex) {
            if (mounted) {
              setState(() {
                _currentBottomSheetPage = pageIndex;
              });
              widget.onBottomSheetPageChanged?.call(pageIndex);
            }
          },
          dataVersion: _dataVersion,
        ),

        Positioned(
          bottom: 64 + 20, // nav height 48 + nav position bottom 16 + extra 10
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child:
                _bottomSheetHeight == 0 &&
                        (_focusedDay.year != DateTime.now().year ||
                            _focusedDay.month != DateTime.now().month)
                    ? Center(
                      key: const ValueKey('today_badge'),
                      child: GestureDetector(
                        onTap: () {
                          final today = DateTime.now();
                          if (mounted) {
                            setState(() {
                              _focusedDay = today;
                              _selectedDay = today;
                            });
                          }
                          _loadRecords();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '오늘',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ],
    );
  }
}
