import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/calendar/widgets/calendar_bottom_sheet.dart';
import 'package:medical_records/calendar/widgets/month_picker_bottom_sheet.dart';
import 'package:medical_records/calendar/widgets/month_selector_widget.dart';
import 'package:medical_records/calendar/widgets/montly_calendar.dart';
import 'package:medical_records/calendar/widgets/view_toggle_widget.dart';
import 'package:medical_records/calendar/widgets/yearly_calendar.dart';
import 'package:medical_records/calendar/widgets/yearly_selector_widget.dart';
import 'package:medical_records/screens/record_foam_page.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
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
  double _bottomSheetHeight = 0.08;

  final Map<DateTime, String> _dayImages = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _bottomSheetHeight = 0.7;
    });
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background),
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildViewToggle(),
                    _isMonthlyView
                        ? _buildMonthSelector()
                        : _buildYearSelector(),
                  ],
                ),
              ),
              Expanded(
                child:
                    _isMonthlyView
                        ? _buildMonthlyCalendar()
                        : _buildYearlyCalendar(),
              ),
            ],
          ),
          _buildBottomSheet(screenHeight),

          if (_bottomSheetHeight <= 0.08)
            Positioned(
              right: 16,
              bottom: context.hp(12),
              child: FloatingActionButton(
                shape: const CircleBorder(),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RecordFoamPage()),
                  );
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
    return ViewToggleWidget(
      isMonthlyView: _isMonthlyView,
      onToggle: (isMonthly) {
        setState(() {
          _isMonthlyView = isMonthly;
        });
      },
    );
  }

  Widget _buildMonthSelector() {
    return MonthSelectorWidget(
      focusedDay: _focusedDay,
      onMonthChanged: (newDate) {
        HapticFeedback.lightImpact();
        setState(() {
          _focusedDay = newDate;
        });
      },
      onMonthTap: () => _showMonthPicker(isMonthlyView: true),
    );
  }

  Widget _buildYearSelector() {
    return YearlySelectorWidget(
      selectedDate: _focusedDay,
      onDateChanged: (newDate) {
        HapticFeedback.lightImpact();
        setState(() {
          _focusedDay = newDate;
        });
      },
      onDateTap: () => _showMonthPicker(isMonthlyView: false),
    );
  }

  Widget _buildMonthlyCalendar() {
    return MonthlyCalendar(
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      calendarFormat: _calendarFormat,
      dayImages: _dayImages,
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        HapticFeedback.lightImpact();
        setState(() {
          _focusedDay = focusedDay;
        });
      },
    );
  }

  Widget _buildYearlyCalendar() {
    return YearlyCalendar(
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      dayImages: _dayImages,
      onDaySelected: (date) {
        setState(() {
          _selectedDay = date;
          _bottomSheetHeight = 0.7;
        });
      },
    );
  }

  Widget _buildBottomSheet(double screenHeight) {
    return CalendarBottomSheet(
      bottomSheetHeight: _bottomSheetHeight,
      selectedDay: _selectedDay,
      dayImages: _dayImages,
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
    );
  }
}
