// calendar_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/calendar/widgets/calendar_bottom_sheet_handle.dart';
import 'package:medical_records/calendar/widgets/calendar_record_detail.dart';
import 'package:medical_records/calendar/widgets/calendar_records_list.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';

class CalendarBottomSheet extends StatefulWidget {
  final double bottomSheetHeight;
  final DateTime? selectedDay;
  final Function(double) onHeightChanged;
  final Function(DateTime) onDateChanged;
  final VoidCallback? onDataChanged;

  const CalendarBottomSheet({
    Key? key,
    required this.bottomSheetHeight,
    required this.selectedDay,
    required this.onHeightChanged,
    required this.onDateChanged,
    this.onDataChanged,
  }) : super(key: key);

  @override
  State<CalendarBottomSheet> createState() => CalendarBottomSheetState();
}

class CalendarBottomSheetState extends State<CalendarBottomSheet> {
  List<Map<String, dynamic>> _dayRecords = [];
  Map<String, dynamic>? _selectedRecord;
  bool _isLoading = false;

  // PageView 관련 변수
  late PageController _pageController;
  int _currentPageIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.selectedDay != null) {
      _loadDayRecords();
    }
  }

  @override
  void didUpdateWidget(CalendarBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bottomSheetHeight == 0 && widget.bottomSheetHeight > 0) {
      // 바텀시트가 다시 열렸을 때 상태 초기화
      setState(() {
        _selectedRecord = null;
        _currentPageIndex = 0;
      });
      _resetToListView();

      if (widget.selectedDay != null) {
        _loadDayRecords();
      }
    }

    if (widget.selectedDay != oldWidget.selectedDay &&
        widget.selectedDay != null) {
      print('새로운 날짜가 클릭 됐어요');
      _loadDayRecords();
      setState(() {
        _selectedRecord = null;
        _currentPageIndex = 0;
      });
      _resetToListView();
    }
    print('기존 날짜가 클릭 됐어요');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void refreshData() {
    print('bottom sheet refresh data');
    _loadDayRecords();
    // 현재 선택된 레코드가 있다면 해당 레코드도 다시 로드
    if (_selectedRecord != null) {
      _refreshSelectedRecord();
    }
  }

  Future<void> _refreshSelectedRecord() async {
    if (_selectedRecord == null) return;

    try {
      final recordId = _selectedRecord!['record_id'];
      final updatedRecord = await DatabaseService().getRecord(recordId);

      if (mounted && updatedRecord != null) {
        setState(() {
          _selectedRecord = updatedRecord;
        });
      }
    } catch (e) {
      print('레코드 새로고침 실패: $e');
    }
  }

  Future<void> _loadDayRecords() async {
    if (widget.selectedDay == null) return;

    setState(() => _isLoading = true);

    try {
      // 로컬 시간 기준으로 날짜 범위 설정
      final startOfDay = DateTime(
        widget.selectedDay!.year,
        widget.selectedDay!.month,
        widget.selectedDay!.day,
      );
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

      final records = await DatabaseService().getRecordsByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (mounted) {
        setState(() {
          _dayRecords =
              records.toList()..sort((a, b) {
                final aDate = DateTime.parse(a['start_date']).toLocal();
                final bDate = DateTime.parse(b['start_date']).toLocal();
                return aDate.compareTo(bDate);
              });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('레코드를 불러오는데 실패했습니다: $e')));
      }
    }
  }

  // pageView 관련
  void _resetToListView() {
    setState(() {
      _selectedRecord = null;
      _currentPageIndex = 0;
    });
    if (_currentPageIndex != 0) {
      _navigateToPage(0);
    }
  }

  void _navigateToPage(int pageIndex) {
    if (_isAnimating || !_pageController.hasClients) return;

    setState(() {
      _isAnimating = true;
    });

    _pageController
        .animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
  }

  void _onRecordTap(Map<String, dynamic> record) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedRecord = record;
    });
    _navigateToPage(1);
  }

  void _onBackToList() {
    HapticFeedback.lightImpact();
    _navigateToPage(0);
  }

  Future<void> _onRecordUpdated() async {
    await _loadDayRecords();
    await _refreshSelectedRecord();
    widget.onDataChanged?.call(); // 부모 위젯에 알림
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: 0,
      height: screenHeight * widget.bottomSheetHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            CalendarBottomSheetHandle(
              dayRecords: _dayRecords,
              selectedDay: widget.selectedDay,
              selectedRecord: _selectedRecord,
              currentPageIndex: _currentPageIndex,
              currentHeight: widget.bottomSheetHeight,
              onHeightChanged: widget.onHeightChanged,
              onBackPressed: _onBackToList,
              onRecordUpdated: _onRecordUpdated,
            ),
            Divider(color: AppColors.surface),
            if (widget.bottomSheetHeight > 0.1 && widget.selectedDay != null)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  children: [
                    // 첫 번째 페이지: 레코드 리스트
                    CalendarRecordsList(
                      dayRecords: _dayRecords,
                      isLoading: _isLoading,
                      onHeightChanged: widget.onHeightChanged,
                      onRecordTap: _onRecordTap,
                    ),
                    // 두 번째 페이지: 레코드 상세
                    _selectedRecord != null
                        ? CalendarRecordDetail(
                          record: _selectedRecord!,
                          onBackPressed: _onBackToList,
                        )
                        : Container(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
