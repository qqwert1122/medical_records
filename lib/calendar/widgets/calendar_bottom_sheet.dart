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
  final Future<List<Map<String, dynamic>>> Function() selectedDayRecordsFetcher;
  final Function(double) onHeightChanged;
  final Function(DateTime) onDateChanged;
  final VoidCallback? onDataChanged;
  final Function(int)? onPageChanged;
  final int dataVersion;

  const CalendarBottomSheet({
    Key? key,
    required this.bottomSheetHeight,
    required this.selectedDay,
    required this.selectedDayRecordsFetcher,
    required this.onHeightChanged,
    required this.onDateChanged,
    this.onDataChanged,
    this.onPageChanged,
    required this.dataVersion,
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
      if (mounted) {
        setState(() {
          _selectedRecord = null;
          _currentPageIndex = 0;
        });
      }
      _resetToListView();

      if (widget.selectedDay != null) {
        _loadDayRecords();
      }
    }

    if (widget.selectedDay != oldWidget.selectedDay &&
        widget.selectedDay != null) {
      _loadDayRecords();
      if (mounted) {
        setState(() {
          _selectedRecord = null;
          _currentPageIndex = 0;
        });
      }
      _resetToListView();
    }

    if (widget.dataVersion != oldWidget.dataVersion) {
      _loadDayRecords();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> onRecordUpdated() async {
    await _loadDayRecords();

    if (_selectedRecord != null) {
      final recordId = _selectedRecord!['record_id'];

      final updatedRecord = _dayRecords.firstWhere(
        (r) => r['record_id'] == recordId,
        orElse: () => _selectedRecord!,
      );

      if (mounted) {
        setState(() {
          _selectedRecord = updatedRecord;
        });
      }
    }

    widget.onDataChanged?.call();
  }

  Future<void> _loadDayRecords() async {
    if (widget.selectedDay == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      // Future에서 데이터 가져오기
      final records = await widget.selectedDayRecordsFetcher();

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
        Set<int> addedImageIds = {};

        for (final history in recordHistories) {
          final historyImages = await DatabaseService().getImages(
            history['history_id'],
          );
          for (final image in historyImages) {
            final imageId = image['image_id'] as int;
            if (!addedImageIds.contains(imageId)) {
              addedImageIds.add(imageId);
              allImages.add({...image, 'record_date': history['record_date']});
            }
          }

          final memoText = (history['memo'] as String? ?? '').trim();
          if (memoText.isNotEmpty) {
            allMemos.add(memoText);
          }
        }

        allImages.sort(
          (a, b) => DateTime.parse(
            a['record_date'],
          ).compareTo(DateTime.parse(b['record_date'])),
        );

        images[recordId] = allImages;
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
    if (mounted) {
      setState(() {
        _selectedRecord = null;
        _currentPageIndex = 0;
      });
    }
    if (_currentPageIndex != 0) {
      _navigateToPage(0);
    }
  }

  void _navigateToPage(int pageIndex) {
    if (_isAnimating || !_pageController.hasClients) return;

    if (mounted) {
      setState(() {
        _isAnimating = true;
      });
    }
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
              _currentPageIndex = pageIndex;
            });
            widget.onPageChanged?.call(pageIndex);
          }
        });
  }

  void _onRecordTap(Map<String, dynamic> record) {
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() {
        _selectedRecord = record;
      });
    }
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
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.backgroundSecondary,
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
                onRecordUpdated: onRecordUpdated,
                onDateChanged: widget.onDateChanged,
              ),
            ),

            if (widget.bottomSheetHeight > 0.1 && widget.selectedDay != null)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    if (mounted) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    }
                    widget.onPageChanged?.call(index);
                  },
                  children: [
                    // 첫 번째 페이지: 레코드 리스트
                    CalendarRecordsList(
                      key: ValueKey(
                        'records_${widget.dataVersion}_${widget.selectedDay?.toIso8601String()}',
                      ),
                      dayRecords: _dayRecords,
                      histories: _recordHistories,
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
                          pageIndex: _currentPageIndex,
                          onDataUpdated: onRecordUpdated,
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
