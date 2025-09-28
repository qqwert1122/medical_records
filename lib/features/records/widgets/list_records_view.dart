import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/features/form/screens/record_form_page.dart';
import 'package:medical_records/features/analysis/enum/analysis_range.dart';
import 'package:medical_records/features/analysis/widgets/range_selector.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/services/review_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/components/date_range_picker_bottom_sheet.dart';
import 'package:medical_records/components/record_detail_bottom_sheet.dart';
import 'package:intl/intl.dart';

class ListRecordsView extends StatefulWidget {
  const ListRecordsView({super.key});

  @override
  State<ListRecordsView> createState() => _ListRecordsViewState();
}

class _ListRecordsViewState extends State<ListRecordsView> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _filterStatus = 'ALL'; // ALL, ONGOING, COMPLETED
  AnalysisRange _dateRange = AnalysisRange.month; // 기본값: 최근 1개월
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  Map<int, List<Map<String, dynamic>>> _recordImages = {};

  // 페이지네이션 관련
  static const int _pageSize = 50; // 한 번에 로드할 레코드 수
  int _currentPage = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadRecords(isRefresh: true);
  }

  Future<void> _loadImages() async {
    final Map<int, List<Map<String, dynamic>>> images = {};

    for (final record in _records) {
      final recordId = record['record_id'];
      try {
        // 해당 record의 모든 history 조회
        final histories = await DatabaseService().getHistories(recordId);

        // 각 history의 이미지들을 수집
        List<Map<String, dynamic>> allImages = [];
        for (final history in histories) {
          final historyId = history['history_id'];
          final historyImages = await DatabaseService().getImages(historyId);
          allImages.addAll(historyImages);
        }

        images[recordId] = allImages;
      } catch (e) {
        images[recordId] = [];
      }
    }

    if (mounted) {
      setState(() {
        _recordImages = images;
      });
    }
  }

  DateTime? _getStartDateFromRange(AnalysisRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (range) {
      case AnalysisRange.today:
        return today;
      case AnalysisRange.week:
        return now.subtract(Duration(days: 7));
      case AnalysisRange.month:
        return DateTime(now.year, now.month - 1, now.day);
      case AnalysisRange.threeMonths:
        return DateTime(now.year, now.month - 3, now.day);
      case AnalysisRange.year:
        return DateTime(now.year - 1, now.month, now.day);
      case AnalysisRange.custom:
        return _customStartDate;
      case AnalysisRange.all:
        return null; // 전체 기간
    }
  }

  Future<void> _showDateRangePicker() async {
    final selectedRange = await DateRangePickerBottomSheet.show(context);

    if (selectedRange != null) {
      setState(() {
        _customStartDate = selectedRange.start;
        _customEndDate = selectedRange.end;
        _dateRange = AnalysisRange.custom;
      });
      _loadRecords(isRefresh: true);
    }
  }

  Future<void> _loadRecords({bool isRefresh = true}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMoreData = true;
        _records = <Map<String, dynamic>>[];
        _recordImages = <int, List<Map<String, dynamic>>>{};
      });
    } else {
      if (_isLoadingMore || !_hasMoreData) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final startDate = _getStartDateFromRange(_dateRange);
      final db = await DatabaseService().database;

      // 기본 쿼리 조건
      String whereClause = 'deleted_at IS NULL';
      List<Object?> whereArgs = [];

      // 상태 필터 추가
      if (_filterStatus == 'ONGOING') {
        whereClause += ' AND end_date IS NULL';
      } else if (_filterStatus == 'COMPLETED') {
        whereClause += ' AND end_date IS NOT NULL';
      }

      // 기간 필터 추가
      if (startDate != null) {
        whereClause += ' AND start_date >= ?';
        whereArgs.add(startDate.toIso8601String());

        // 커스텀 기간 선택의 경우 종료일도 고려
        if (_dateRange == AnalysisRange.custom && _customEndDate != null) {
          final endOfDay = DateTime(
            _customEndDate!.year,
            _customEndDate!.month,
            _customEndDate!.day,
            23,
            59,
            59,
          );
          whereClause += ' AND start_date <= ?';
          whereArgs.add(endOfDay.toIso8601String());
        }
      }

      final records = await db.query(
        'records',
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'start_date DESC',
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _records = List<Map<String, dynamic>>.from(records);
          } else {
            _records = List<Map<String, dynamic>>.from(_records)
              ..addAll(records);
          }
          _hasMoreData = records.length == _pageSize;
          _currentPage++;
          _isLoading = false;
          _isLoadingMore = false;
        });
        _loadImages();
      }
    } catch (e) {
      print('기록 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreRecords() async {
    await _loadRecords(isRefresh: false);
  }

  Future<void> _showRecordDetail(Map<String, dynamic> record) async {
    try {
      final recordId = record['record_id'];

      // 해당 record의 모든 데이터 로드
      final histories = await DatabaseService().getHistories(recordId);
      final images = _recordImages[recordId] ?? [];

      // 메모 추출
      final memos = <String>[];
      for (final history in histories) {
        final memo = history['memo'];
        if (memo != null && memo.toString().trim().isNotEmpty) {
          memos.add(memo.toString());
        }
      }

      if (mounted) {
        RecordDetailBottomSheet.show(
          context,
          record: record,
          histories: histories,
          images: images,
          memos: memos,
          onDataUpdated: () {
            // 레코드가 업데이트되면 목록 새로고침
            _loadRecords(isRefresh: true);
          },
        );
      }
    } catch (e) {
      print('레코드 상세 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterTabs(), // 필터
        // 필터 결과 요약
        // 기록 리스트
        Expanded(
          child:
              _isLoading
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('기록 로딩 중...', style: AppTextStyle.body),
                      ],
                    ),
                  )
                  : _records.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 100.0,
                    ),
                    itemCount: _records.length + 1 + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildResultsSummary();
                      }
                      if (index == _records.length + 1 && _hasMoreData) {
                        return _buildLoadMoreButton();
                      }
                      return _buildRecordItem(_records[index - 1]);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterTab('전체', 'ALL'),
            SizedBox(width: 8),
            _buildFilterTab('진행중', 'ONGOING'),
            SizedBox(width: 8),
            _buildFilterTab('완료', 'COMPLETED'),
            SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: RangeSelector(
                value: _dateRange,
                onChanged: (newRange) async {
                  if (newRange == AnalysisRange.custom) {
                    await _showDateRangePicker();
                  } else {
                    setState(() {
                      _dateRange = newRange;
                      _customStartDate = null;
                      _customEndDate = null;
                    });
                    await _loadRecords(isRefresh: true);
                  }
                },
              ),
            ),
            SizedBox(width: 8),
            if (_dateRange == AnalysisRange.custom &&
                _customStartDate != null &&
                _customEndDate != null)
              GestureDetector(
                onTap: () async {
                  setState(() {
                    _dateRange = AnalysisRange.month;
                    _customStartDate = null;
                    _customEndDate = null;
                  });
                  await _loadRecords(isRefresh: true);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 10,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    if (_isLoading) {
      return SizedBox.shrink();
    }

    String dateRangeText = '';
    final now = DateTime.now();

    switch (_dateRange) {
      case AnalysisRange.today:
        dateRangeText = DateFormat('yyyy.MM.dd').format(now);
        break;
      case AnalysisRange.week:
        final weekAgo = now.subtract(Duration(days: 7));
        dateRangeText =
            '${DateFormat('yyyy.MM.dd').format(weekAgo)} ~ ${DateFormat('yyyy.MM.dd').format(now)}';
        break;
      case AnalysisRange.month:
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        dateRangeText =
            '${DateFormat('yyyy.MM.dd').format(monthAgo)} ~ ${DateFormat('yyyy.MM.dd').format(now)}';
        break;
      case AnalysisRange.threeMonths:
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        dateRangeText =
            '${DateFormat('yyyy.MM.dd').format(threeMonthsAgo)} ~ ${DateFormat('yyyy.MM.dd').format(now)}';
        break;
      case AnalysisRange.year:
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        dateRangeText =
            '${DateFormat('yyyy.MM.dd').format(yearAgo)} ~ ${DateFormat('yyyy.MM.dd').format(now)}';
        break;
      case AnalysisRange.custom:
        if (_customStartDate != null && _customEndDate != null) {
          dateRangeText =
              '${DateFormat('yyyy.MM.dd').format(_customStartDate!)} ~ ${DateFormat('yyyy.MM.dd').format(_customEndDate!)}';
        }
        break;
      case AnalysisRange.all:
        dateRangeText = '전체';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        '총 ${_records.length}건, 기간: $dateRangeText',
        style: AppTextStyle.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () async {
        setState(() => _filterStatus = status);
        await _loadRecords(isRefresh: true);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: AppTextStyle.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final startDate = DateTime.parse(record['start_date']);
    final endDate =
        record['end_date'] != null ? DateTime.parse(record['end_date']) : null;
    final color = Color(int.parse(record['color']));
    final isComplete = endDate != null;

    return GestureDetector(
      onTap: () => _showRecordDetail(record),
      child: Container(
        margin: EdgeInsets.only(bottom: context.hp(2)),
        padding: context.paddingHorizXS,
        decoration: BoxDecoration(
          color: isComplete ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 색깔 바, 증상 이름, 부위 이름, 뱃지
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Wrap(
                        spacing: 10,
                        children: [
                          Text(
                            record['symptom_name'] ?? '증상 없음',
                            style: AppTextStyle.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  isComplete
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            record['spot_name'] ?? '부위 없음',
                            style: AppTextStyle.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                      SizedBox(height: context.hp(0.5)),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          _buildTimeRow(
                            endDate != null ? '완료' : '시작',
                            endDate != null
                                ? DateFormat('MM.dd').format(endDate)
                                : DateFormat('MM.dd').format(startDate),
                          ),
                          _buildStatusBadge(record),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildImageStack(_recordImages[record['record_id']] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4),
        Text(
          time,
          style: AppTextStyle.caption.copyWith(color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> record) {
    final endDate = record['end_date'];

    // 상태 판단
    String status;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (endDate != null) {
      // 1. 종료된 경우
      status = '완료';
      backgroundColor = AppColors.backgroundSecondary;
      textColor = AppColors.textPrimary;
      icon = LucideIcons.checkCircle;
    } else {
      // 2. 진행중인 경우
      status = '진행중';
      backgroundColor = Colors.blueAccent;
      textColor = AppColors.white;
      icon = LucideIcons.circleDashed;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: textColor),
          SizedBox(width: 4),
          Text(
            status,
            style: AppTextStyle.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageStack(List<Map<String, dynamic>> images) {
    final displayCount = images.length > 3 ? 3 : images.length;
    final remainingCount = images.length - displayCount;

    const double tileSize = 50.0;
    const double step = 40.0;
    double stackWidth = tileSize + (displayCount - 1) * step;

    if (images.isEmpty) {
      return SizedBox(width: tileSize, height: tileSize);
    }

    return SizedBox(
      height: tileSize,
      width: stackWidth,
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            final image = images[index];

            return Positioned(
              left: index * step,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.background, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image['image_url']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.lightGrey,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 20,
                          color: AppColors.lightGrey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textPrimary,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child:
            _isLoadingMore
                ? CircularProgressIndicator(color: AppColors.primary)
                : ElevatedButton(
                  onPressed: _loadMoreRecords,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    '더 보기 (${_pageSize}개)',
                    style: AppTextStyle.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_box.png',
            width: context.wp(30),
            height: context.wp(30),
            color: AppColors.lightGrey,
          ),
          Text(
            '기록된 증상이 없어요',
            style: AppTextStyle.body.copyWith(color: AppColors.lightGrey),
          ),
        ],
      ),
    );
  }
}
