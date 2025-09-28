import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/features/records/widgets/list_records_view.dart';
import 'package:medical_records/features/records/widgets/history_records_view.dart';
import 'package:medical_records/features/records/widgets/montly_calendar_view.dart';
import 'package:medical_records/features/records/widgets/yearly_calendar_view.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordsPage extends StatefulWidget {
  final Function(double)? onBottomSheetHeightChanged;
  final Function(int)? onBottomSheetPageChanged;

  const RecordsPage({
    super.key,
    this.onBottomSheetHeightChanged,
    this.onBottomSheetPageChanged,
  });

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentTabIndex = 0;
  DateTime? _selectedMonthForMonthlyView;

  final List<String> _tabLabels = ['월간', '연간', '목록', '히스토리'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentTabIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToMonthlyView(DateTime monthDate) {
    setState(() {
      _selectedMonthForMonthlyView = monthDate;
      _currentTabIndex = 0; // 월간 탭으로 이동
    });
    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
                children: [
                  MontlyCalendarView(
                    onBottomSheetHeightChanged:
                        widget.onBottomSheetHeightChanged,
                    onBottomSheetPageChanged: widget.onBottomSheetPageChanged,
                    initialFocusedMonth: _selectedMonthForMonthlyView,
                  ), // 월간 캘린더 뷰
                  YearlyCalendarView(
                    onBottomSheetHeightChanged:
                        widget.onBottomSheetHeightChanged,
                    onBottomSheetPageChanged: widget.onBottomSheetPageChanged,
                    onMonthTap: _navigateToMonthlyView,
                  ), // 연간 캘린더 뷰
                  ListRecordsView(), // 목록 뷰
                  HistoryRecordsView(), // 히스토리 뷰
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              _tabLabels.asMap().entries.map((entry) {
                final index = entry.key;
                final label = entry.value;
                return _buildTabButton(label, index);
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.transparent,
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
}
