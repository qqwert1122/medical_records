import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/calendar/widgets/calendar_bottom_sheet.dart';
import 'package:medical_records/calendar/widgets/month_picker_bottom_sheet.dart';
import 'package:medical_records/calendar/widgets/montly_calendar.dart';
import 'package:medical_records/calendar/widgets/calendar_header_widget.dart';
import 'package:medical_records/calendar/widgets/yearly_calendar.dart';
import 'package:medical_records/records/screens/record_foam_page.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isMonthlyView = true;
  double _bottomSheetHeight = 0;
  final Map<DateTime, List<Color>> _dayRecords = {};

  // CalendarBottomSheet에 전달할 콜백을 위한 GlobalKey
  final GlobalKey<CalendarBottomSheetState> _bottomSheetKey = GlobalKey();
  final GlobalKey<YearlyCalendarState> _yearlyCalendarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final records = await DatabaseService().getRecordsByDateRange(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
    setState(() {
      _dayRecords.clear();

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

        if (_dayRecords.containsKey(dateKey)) {
          _dayRecords[dateKey]!.add(color);
        } else {
          _dayRecords[dateKey] = [color];
        }
      }
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _bottomSheetHeight = 0.4;
    });
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
                    _isMonthlyView
                        ? _buildMonthlyCalendar()
                        : _buildYearlyCalendar(),
              ),
            ],
          ),
          _buildBottomSheet(screenHeight),

          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RecordFoamPage(selectedDate: _selectedDay),
                  ),
                );

                if (result == true) {
                  await _onDataChanged();
                }
              },
              backgroundColor: Colors.pinkAccent,
              child: const Icon(LucideIcons.plus, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return CalendarHeaderWidget(
      isMonthlyView: _isMonthlyView,
      focusedDay: _focusedDay,
      onToggle: (isMonthly) {
        setState(() {
          _isMonthlyView = isMonthly;
        });
      },
      onDateTap: () => _showMonthPicker(isMonthlyView: _isMonthlyView),
    );
  }

  Widget _buildMonthlyCalendar() {
    return MonthlyCalendar(
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      calendarFormat: _calendarFormat,
      dayRecords: _dayRecords,
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
      },
    );
  }

  Widget _buildBottomSheet(double screenHeight) {
    return CalendarBottomSheet(
      key: _bottomSheetKey,
      bottomSheetHeight: _bottomSheetHeight,
      selectedDay: _selectedDay,
      onHeightChanged: (newHeight) {
        setState(() {
          _bottomSheetHeight = newHeight;
        });
      },
      onDateChanged: (newDate) {
        setState(() {
          _selectedDay = newDate;
          _focusedDay = newDate;
        });
      },
      onDataChanged: _onDataChanged,
    );
  }
}
