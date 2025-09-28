import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/features/calendar/widgets/calendar_bottom_sheet.dart';
import 'package:medical_records/features/calendar/widgets/month_picker_bottom_sheet.dart';
import 'package:medical_records/features/calendar/widgets/calendar_header_widget.dart';
import 'package:medical_records/features/calendar/widgets/yearly_calendar.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';

class YearlyCalendarView extends StatefulWidget {
  final Function(double)? onBottomSheetHeightChanged;
  final Function(int)? onBottomSheetPageChanged;
  final Function(DateTime)? onMonthTap;

  const YearlyCalendarView({
    Key? key,
    this.onBottomSheetHeightChanged,
    this.onBottomSheetPageChanged,
    this.onMonthTap,
  }) : super(key: key);

  @override
  State<YearlyCalendarView> createState() => _YearlyCalendarViewState();
}

class _YearlyCalendarViewState extends State<YearlyCalendarView>
    with TickerProviderStateMixin {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  double _bottomSheetHeight = 0;

  final GlobalKey<YearlyCalendarState> _yearlyCalendarKey = GlobalKey();
  int _currentBottomSheetPage = 0;
  int _dataVersion = 0;
  bool _isRefreshing = false;

  // 연간 뷰로 고정
  final bool _isMonthlyView = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
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

  void _showMonthPicker() async {
    HapticFeedback.lightImpact();
    final selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MonthPickerBottomSheet(
            initialDate: _focusedDay,
            isMonthlyView: false,
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
      _yearlyCalendarKey.currentState?.refreshData();
      if (mounted) {
        setState(() {
          _dataVersion++;
        });
      }
    } finally {
      _isRefreshing = false;
    }
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
              SafeArea(bottom: false, child: _buildHeader()),
              Expanded(child: _buildYearlyCalendar()),
            ],
          ),
          _buildBottomSheet(screenHeight),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return CalendarHeaderWidget(
      isMonthlyView: _isMonthlyView,
      focusedDay: _focusedDay,
      onDateTap: _showMonthPicker,
    );
  }

  Widget _buildYearlyCalendar() {
    return YearlyCalendar(
      key: _yearlyCalendarKey,
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      onDaySelected: (date) {
        if (mounted) {
          setState(() {
            _selectedDay = date;
            _bottomSheetHeight = 0.5;
          });
        }
        widget.onBottomSheetHeightChanged?.call(0.5);
      },
      onMonthTap: (monthDate) {
        // 월 클릭 시 월간 탭으로 이동
        widget.onMonthTap?.call(monthDate);
      },
    );
  }

  Widget _buildBottomSheet(double screenHeight) {
    return CalendarBottomSheet(
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
    );
  }
}
