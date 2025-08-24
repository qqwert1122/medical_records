import 'package:flutter/material.dart';
import 'package:medical_records/calendar/widgets/calendar_day_cell.dart';
import 'package:medical_records/calendar/widgets/calendar_day_cell_bar.dart';
import 'package:medical_records/calendar/widgets/weekly_record_overlay.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medical_records/styles/app_size.dart';

class MonthlyCalendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, List<Color>> dayRecords;
  final Map<DateTime, Map<int, RecordInfo>> weekRecordSlots;
  final Map<String, String> recordTitles;
  final Map<String, DateTime> recordStartDates;
  final Map<String, DateTime> recordEndDates;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Function(double)? onHeightChanged;
  final double bottomSheetHeight;

  const MonthlyCalendar({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.dayRecords,
    required this.weekRecordSlots,
    required this.recordTitles,
    required this.recordStartDates,
    required this.recordEndDates,
    required this.onDaySelected,
    required this.onPageChanged,
    this.onHeightChanged,
    this.bottomSheetHeight = 0.0,
  }) : super(key: key);

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _dotsController;
  late AnimationController _heightController;
  late Animation<double> _overlayAnimation;
  late Animation<double> _dotsAnimation;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    // 막대바 애니메이션
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeIn,
    );

    // dots 애니메이션
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _dotsAnimation = CurvedAnimation(
      parent: _dotsController,
      curve: Curves.easeIn,
    );

    // 높이 애니메이션 추가
    _heightController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  // initState에서 context.hp()를 사용할 수 없어 didChangeDependencies에서 초기화
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // context를 사용하는 애니메이션 초기화
    _heightAnimation = Tween<double>(
      begin: context.hp(5),
      end: context.hp(13),
    ).animate(
      CurvedAnimation(parent: _heightController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _dotsController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calendarHeightFactor = widget.bottomSheetHeight > 0 ? 0.5 : 1.0;

    if (calendarHeightFactor == 1.0) {
      _overlayController.forward();
      _dotsController.reset();
      _heightController.forward(); // 높이 증가
    } else {
      _overlayController.reset();
      _dotsController.forward();
      _heightController.reverse(); // 높이 감소
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _heightAnimation,
                  builder: (context, child) {
                    return TableCalendar(
                      key: ValueKey(calendarHeightFactor),
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: widget.focusedDay,
                      calendarFormat: widget.calendarFormat,
                      selectedDayPredicate:
                          (day) => isSameDay(widget.selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        widget.onDaySelected(selectedDay, focusedDay);
                        widget.onHeightChanged?.call(0.5);
                      },
                      onPageChanged: widget.onPageChanged,
                      headerVisible: false,
                      daysOfWeekHeight: context.hp(2),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        weekendStyle: AppTextStyle.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),

                      rowHeight: _heightAnimation.value,
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final dateKey = DateTime(
                            day.year,
                            day.month,
                            day.day,
                          );
                          final prevDateKey = dateKey.subtract(
                            Duration(days: 1),
                          );
                          final nextDateKey = dateKey.add(Duration(days: 1));

                          final colors = widget.dayRecords[dateKey] ?? [];
                          final weekSlots = widget.weekRecordSlots[dateKey];
                          final prevSlots = widget.weekRecordSlots[prevDateKey];
                          final nextSlots = widget.weekRecordSlots[nextDateKey];

                          return calendarHeightFactor == 1.0
                              ? CalendarDayCellBar(
                                day: day,
                                isSelected: false,
                                isOutside: false,
                                recordColors: colors,
                                weekRecordSlots: weekSlots,
                                previousDaySlots: prevSlots,
                                nextDaySlots: nextSlots,
                                recordStartDates: widget.recordStartDates,
                                recordEndDates: widget.recordEndDates,
                              )
                              : CalendarDayCell(
                                day: day,
                                isSelected: false,
                                isOutside: false,
                                recordColors: colors,
                                animation: _dotsAnimation,
                              );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          final dateKey = DateTime(
                            day.year,
                            day.month,
                            day.day,
                          );
                          final prevDateKey = dateKey.subtract(
                            Duration(days: 1),
                          );
                          final nextDateKey = dateKey.add(Duration(days: 1));

                          final colors = widget.dayRecords[dateKey] ?? [];
                          final weekSlots = widget.weekRecordSlots[dateKey];
                          final prevSlots = widget.weekRecordSlots[prevDateKey];
                          final nextSlots = widget.weekRecordSlots[nextDateKey];

                          return calendarHeightFactor == 1.0
                              ? CalendarDayCellBar(
                                day: day,
                                isSelected: true,
                                isOutside: false,
                                recordColors: colors,
                                weekRecordSlots: weekSlots,
                                previousDaySlots: prevSlots,
                                nextDaySlots: nextSlots,
                                recordStartDates: widget.recordStartDates, // 추가
                                recordEndDates: widget.recordEndDates,
                              )
                              : CalendarDayCell(
                                day: day,
                                isSelected: true,
                                isOutside: false,
                                recordColors: colors,
                                animation: _dotsAnimation,
                              );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final dateKey = DateTime(
                            day.year,
                            day.month,
                            day.day,
                          );
                          final prevDateKey = dateKey.subtract(
                            Duration(days: 1),
                          );
                          final nextDateKey = dateKey.add(Duration(days: 1));

                          final colors = widget.dayRecords[dateKey] ?? [];
                          final weekSlots = widget.weekRecordSlots[dateKey];
                          final prevSlots = widget.weekRecordSlots[prevDateKey];
                          final nextSlots = widget.weekRecordSlots[nextDateKey];

                          return calendarHeightFactor == 1.0
                              ? CalendarDayCellBar(
                                day: day,
                                isSelected: false,
                                isToday: true,
                                isOutside: false,
                                recordColors: colors,
                                weekRecordSlots: weekSlots,
                                previousDaySlots: prevSlots,
                                nextDaySlots: nextSlots,
                                recordStartDates: widget.recordStartDates, // 추가
                                recordEndDates: widget.recordEndDates,
                              )
                              : CalendarDayCell(
                                day: day,
                                isSelected: false,
                                isOutside: false,
                                isToday: true,
                                recordColors: colors,
                                animation: _dotsAnimation,
                              );
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          final dateKey = DateTime(
                            day.year,
                            day.month,
                            day.day,
                          );
                          final prevDateKey = dateKey.subtract(
                            Duration(days: 1),
                          );
                          final nextDateKey = dateKey.add(Duration(days: 1));

                          final colors = widget.dayRecords[dateKey] ?? [];
                          final weekSlots = widget.weekRecordSlots[dateKey];
                          final prevSlots = widget.weekRecordSlots[prevDateKey];
                          final nextSlots = widget.weekRecordSlots[nextDateKey];

                          return calendarHeightFactor == 1.0
                              ? CalendarDayCellBar(
                                day: day,
                                isSelected: false,
                                isOutside: true,
                                recordColors: colors,
                                weekRecordSlots: weekSlots,
                                previousDaySlots: prevSlots,
                                nextDaySlots: nextSlots,
                                recordStartDates: widget.recordStartDates,
                                recordEndDates: widget.recordEndDates,
                              )
                              : CalendarDayCell(
                                day: day,
                                isSelected: false,
                                isOutside: true,
                                recordColors: colors,
                                animation: _dotsAnimation,
                              );
                        },
                      ),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: true,
                        outsideDecoration: BoxDecoration(),
                        weekendTextStyle: TextStyle(color: Colors.redAccent),
                        cellMargin: EdgeInsets.all(0),
                      ),
                      locale: 'ko_KR',
                    );
                  },
                ),
                if (calendarHeightFactor == 1.0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: WeeklyRecordOverlay(
                          key: ValueKey(widget.focusedDay),
                          weekRecordSlots: widget.weekRecordSlots,
                          recordStartDates: widget.recordStartDates,
                          recordEndDates: widget.recordEndDates,
                          recordTitles: widget.recordTitles,
                          focusedDay: widget.focusedDay,
                          animation: _overlayAnimation,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
