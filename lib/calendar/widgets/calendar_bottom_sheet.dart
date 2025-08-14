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

  const CalendarBottomSheet({
    Key? key,
    required this.bottomSheetHeight,
    required this.selectedDay,
    required this.onHeightChanged,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  State<CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<CalendarBottomSheet> {
  List<Map<String, dynamic>> _dayRecords = [];
  Map<String, dynamic>? _selectedRecord;
  List<Map<String, dynamic>> _recordImages = [];
  bool _isLoading = false;
  bool _showDetail = false;

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
    if (widget.selectedDay != oldWidget.selectedDay &&
        widget.selectedDay != null) {
      _loadDayRecords();
      setState(() {
        _showDetail = false;
        _selectedRecord = null;
        _recordImages = [];
      });
      _resetToListView();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> _loadRecordImages(int recordId) async {
    try {
      final images = await DatabaseService().getImages(recordId);
      if (mounted) {
        setState(() {
          _recordImages = images;
        });
      }
    } catch (e) {
      print('이미지 로드 실패: $e');
    }
  }

  // pageView 관련
  void _resetToListView() {
    if (_currentPageIndex != 0) {
      _navigateToPage(0);
      setState(() {
        _selectedRecord = null;
      });
    }
  }

  void _navigateToPage(int pageIndex) {
    if (_isAnimating) return;

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
              currentHeight: widget.bottomSheetHeight,
              onHeightChanged: widget.onHeightChanged,
              isDetailView: _showDetail,
            ),
            Divider(color: AppColors.surface),
            if (widget.bottomSheetHeight > 0.1 && widget.selectedDay != null)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // 스와이프 비활성화
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

  Widget _buildRecordsList() {
    return CalendarRecordsList(
      dayRecords: _dayRecords,
      isLoading: _isLoading,
      onHeightChanged: widget.onHeightChanged,
      onRecordTap: (record) async {
        HapticFeedback.lightImpact();
        await _loadRecordImages(record['record_id']);
        setState(() {
          _selectedRecord = record;
          _showDetail = true;
        });
      },
    );
  }

  Widget _buildRecordDetail() {
    if (_selectedRecord == null) return Container();

    return CalendarRecordDetail(
      record: _selectedRecord!,
      onBackPressed: () {
        setState(() {
          _showDetail = false;
          _selectedRecord = null;
          _recordImages = [];
        });
      },
    );
  }
}
