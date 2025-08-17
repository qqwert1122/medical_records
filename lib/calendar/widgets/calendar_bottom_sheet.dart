import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/calendar/widgets/calendar_bottom_sheet_handle.dart';
import 'package:medical_records/calendar/widgets/calendar_record_detail.dart';
import 'package:medical_records/calendar/widgets/calendar_records_list.dart';
import 'package:medical_records/calendar/widgets/weekly_record_overlay.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/services/database_service.dart';

class CalendarBottomSheet extends StatefulWidget {
  final double bottomSheetHeight;
  final DateTime? selectedDay;
  final Map<int, RecordInfo>? dayRecordSlots;
  final Map<String, String>? recordTitles;
  final Function(double) onHeightChanged;
  final Function(DateTime) onDateChanged;
  final VoidCallback? onDataChanged;

  const CalendarBottomSheet({
    Key? key,
    required this.bottomSheetHeight,
    required this.selectedDay,
    this.dayRecordSlots,
    this.recordTitles,
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
  Map<int, List<Map<String, dynamic>>> _recordHistories = {};
  Map<int, List<Map<String, dynamic>>> _recordImages = {};
  Map<int, List<String>> _recordMemos = {};

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
      _loadDayRecords();
      setState(() {
        _selectedRecord = null;
        _currentPageIndex = 0;
      });
      _resetToListView();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void refreshData() {
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
      final updatedRecord = _dayRecords.firstWhere(
        (record) => record['record_id'] == recordId,
        orElse: () => <String, dynamic>{},
      );

      if (mounted && updatedRecord.isNotEmpty) {
        setState(() {
          _selectedRecord = updatedRecord;
        });
      } else {
        // 레코드가 날짜 범위를 벗어났거나 삭제된 경우
        setState(() {
          _selectedRecord = null;
          _currentPageIndex = 0;
        });
        _resetToListView();
      }
    } catch (e) {
      print('레코드 새로고침 실패: $e');
    }
  }

  Future<void> _loadDayRecords() async {
    if (widget.selectedDay == null) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> records = [];

      // 전달받은 슬롯 정보가 있으면 사용
      if (widget.dayRecordSlots != null && widget.recordTitles != null) {
        final recordIds =
            widget.dayRecordSlots!.values.map((info) => info.recordId).toSet();

        for (final recordId in recordIds) {
          final record = await DatabaseService().getRecord(int.parse(recordId));
          if (record != null) {
            records.add(record);
          }
        }
      } else {
        // 기존 로직 (슬롯 정보가 없을 때)
        final startOfDay = DateTime(
          widget.selectedDay!.year,
          widget.selectedDay!.month,
          widget.selectedDay!.day,
        );
        final endOfDay = startOfDay
            .add(const Duration(days: 1))
            .subtract(const Duration(microseconds: 1));

        records = await DatabaseService().getRecordsByDateRange(
          startDate: startOfDay,
          endDate: endOfDay,
        );
      }

      // 레코드 정렬
      records.sort((a, b) {
        final aDate = DateTime.parse(a['start_date']).toLocal();
        final bDate = DateTime.parse(b['start_date']).toLocal();
        return aDate.compareTo(bDate);
      });

      // 각 레코드의 histories, images, memos 로드
      Map<int, List<Map<String, dynamic>>> histories = {};
      Map<int, List<Map<String, dynamic>>> images = {};
      Map<int, List<String>> memos = {};

      for (final record in records) {
        final recordId = record['record_id'];
        final recordHistories = await DatabaseService().getHistories(recordId);
        histories[recordId] = recordHistories;

        List<Map<String, dynamic>> allImages = [];
        List<String> allMemos = [];

        for (final history in recordHistories) {
          final historyImages = await DatabaseService().getImages(
            history['history_id'],
          );
          allImages.addAll(historyImages);

          final memoText = (history['memo'] as String? ?? '').trim();
          if (memoText.isNotEmpty) {
            allMemos.add(memoText);
          }
        }

        images[recordId] = allImages.toSet().toList();
        memos[recordId] = allMemos;
      }

      if (mounted) {
        setState(() {
          _dayRecords = records;
          _recordHistories = histories;
          _recordImages = images;
          _recordMemos = memos;
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
    if (_selectedRecord != null) {
      await _refreshSelectedRecord();
    }
    widget.onDataChanged?.call(); // 부모 위젯에 알림
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: 0,
      height: screenHeight * widget.bottomSheetHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.grey.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: CalendarBottomSheetHandle(
                dayRecords: _dayRecords,
                selectedDay: widget.selectedDay,
                selectedRecord: _selectedRecord,
                currentPageIndex: _currentPageIndex,
                currentHeight: widget.bottomSheetHeight,
                onHeightChanged: widget.onHeightChanged,
                onBackPressed: _onBackToList,
                onRecordUpdated: _onRecordUpdated,
                onDateChanged: widget.onDateChanged,
              ),
            ),

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
                      recordImages: _recordImages,
                      recordMemos: _recordMemos,
                      isLoading: _isLoading,
                      onHeightChanged: widget.onHeightChanged,
                      onRecordTap: _onRecordTap,
                    ),
                    // 두 번째 페이지: 레코드 상세
                    _selectedRecord != null
                        ? CalendarRecordDetail(
                          record: _selectedRecord!,
                          histories:
                              _recordHistories[_selectedRecord!['record_id']] ??
                              [],
                          images:
                              _recordImages[_selectedRecord!['record_id']] ??
                              [],
                          memos:
                              _recordMemos[_selectedRecord!['record_id']] ?? [],
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
