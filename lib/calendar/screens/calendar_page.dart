import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/calendar/widgets/calendar_bottom_sheet.dart';
import 'package:medical_records/calendar/widgets/month_picker_bottom_sheet.dart';
import 'package:medical_records/calendar/widgets/montly_calendar.dart';
import 'package:medical_records/calendar/widgets/calendar_header_widget.dart';
import 'package:medical_records/calendar/widgets/weekly_record_overlay.dart';
import 'package:medical_records/calendar/widgets/yearly_calendar.dart';
import 'package:medical_records/records/screens/record_foam_page.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final bool isMonthlyView;
  final Function(double)? onBottomSheetHeightChanged;
  const CalendarPage({
    Key? key,
    required this.isMonthlyView,
    this.onBottomSheetHeightChanged,
  }) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  double _bottomSheetHeight = 0;
  final Map<DateTime, List<Color>> _dayRecords = {};
  final Map<DateTime, Map<int, RecordInfo>> _weekRecordSlots = {};
  final Map<String, String> _recordTitles = {};
  Map<String, DateTime> _recordStartDates = {};
  Map<String, DateTime> _recordEndDates = {};

  // CalendarBottomSheet에 전달할 콜백을 위한 GlobalKey
  final GlobalKey<CalendarBottomSheetState> _bottomSheetKey = GlobalKey();
  final GlobalKey<YearlyCalendarState> _yearlyCalendarKey = GlobalKey();

  int _currentBottomSheetPage = 0;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final startOfWeek = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    final endOfWeek = lastDay.add(Duration(days: 6 - (lastDay.weekday % 7)));

    final records = await DatabaseService().getRecordsByDateRange(
      startDate: startOfWeek,
      endDate: endOfWeek,
    );

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

        final normalizedStart = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final normalizedEnd = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
        );

        // 시작/종료 날짜 저장
        recordStartDates[recordId] = normalizedStart;
        recordEndDates[recordId] = normalizedEnd;

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
                    .where((r) => weekRecordSlots[weekKey]!.containsKey(r.key))
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

  String _getWeekKey(DateTime date) {
    final weekday = date.weekday % 7;
    final sunday = date.subtract(Duration(days: weekday));
    return '${sunday.year}-${sunday.month}-${sunday.day}';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _bottomSheetHeight = 0.4;
      _currentBottomSheetPage = 0;
    });
    widget.onBottomSheetHeightChanged?.call(0.4);
    _loadRecords();
  }

  void _showMonthPicker({bool isMonthlyView = true}) async {
    final selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MonthPickerBottomSheet(
            initialDate: _focusedDay,
            isMonthlyView: isMonthlyView,
          ),
    );

    if (selectedDate != null) {
      setState(() {
        _focusedDay = selectedDate;
      });
    }
  }

  Future<void> _onDataChanged() async {
    _yearlyCalendarKey.currentState?.refreshData();
    _bottomSheetKey.currentState?.refreshData();
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(bottom: false, child: _buildViewToggle()),
              Expanded(
                child:
                    widget.isMonthlyView
                        ? _buildMonthlyCalendar()
                        : _buildYearlyCalendar(),
              ),
            ],
          ),
          _buildBottomSheet(screenHeight),

          Positioned(
            bottom: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child:
                  _currentBottomSheetPage == 0
                      ? SizedBox(
                        height: 48,
                        width: 48,
                        child: FloatingActionButton(
                          key: const ValueKey('add_fab'),
                          shape: const CircleBorder(),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => RecordFoamPage(
                                      selectedDate: _selectedDay,
                                    ),
                              ),
                            );

                            if (result == true) {
                              await _onDataChanged();
                            }
                          },
                          backgroundColor: AppColors.primary,
                          child: const Icon(
                            LucideIcons.plus,
                            color: Colors.white,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return CalendarHeaderWidget(
      isMonthlyView: widget.isMonthlyView,
      focusedDay: _focusedDay,

      onDateTap: () => _showMonthPicker(isMonthlyView: widget.isMonthlyView),
    );
  }

  Widget _buildMonthlyCalendar() {
    return MonthlyCalendar(
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
        setState(() {
          _focusedDay = focusedDay;
        });
        _loadRecords();
      },
      onHeightChanged: (factor) {
        setState(() {
          _bottomSheetHeight = factor;
          widget.onBottomSheetHeightChanged?.call(factor);
        });
      },
    );
  }

  Widget _buildYearlyCalendar() {
    return YearlyCalendar(
      key: _yearlyCalendarKey,
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      onDaySelected: (date) {
        setState(() {
          _selectedDay = date;
          _bottomSheetHeight = 0.4;
        });

        widget.onBottomSheetHeightChanged?.call(0.4);
      },
    );
  }

  Widget _buildBottomSheet(double screenHeight) {
    final selectedDateKey =
        _selectedDay != null
            ? DateTime(
              _selectedDay!.year,
              _selectedDay!.month,
              _selectedDay!.day,
            )
            : null;

    final selectedDaySlots =
        selectedDateKey != null ? _weekRecordSlots[selectedDateKey] : null;

    return CalendarBottomSheet(
      key: _bottomSheetKey,
      bottomSheetHeight: _bottomSheetHeight,
      selectedDay: _selectedDay,
      dayRecordSlots: selectedDaySlots,
      recordTitles: _recordTitles,
      onHeightChanged: (newHeight) {
        setState(() {
          _bottomSheetHeight = newHeight;
          if (newHeight == 0) {
            _currentBottomSheetPage = 0;
          }
          widget.onBottomSheetHeightChanged?.call(newHeight);
        });
      },
      onDateChanged: (newDate) {
        setState(() {
          _selectedDay = newDate;
          _focusedDay = newDate;
        });
      },
      onDataChanged: _onDataChanged,
      onPageChanged: (pageIndex) {
        setState(() {
          _currentBottomSheetPage = pageIndex;
        });
      },
    );
  }
}
