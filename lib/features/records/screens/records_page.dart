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
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  int _currentTabIndex = 0;
  DateTime? _selectedMonthForMonthlyView;

  final List<String> _tabLabels = [
    '월간', '연간', '목록',
    //  '히스토리'
  ];

  @override
  void initState() {
    super.initState();
    _tabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentTabIndex = index;
    });
  }

  void _navigateToMonthlyView(DateTime monthDate) {
    setState(() {
      _selectedMonthForMonthlyView = monthDate;
      _currentTabIndex = 0; // 월간 탭으로 이동
    });
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
            Expanded(child: _buildCurrentTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return MontlyCalendarView(
          onBottomSheetHeightChanged: widget.onBottomSheetHeightChanged,
          onBottomSheetPageChanged: widget.onBottomSheetPageChanged,
          initialFocusedMonth: _selectedMonthForMonthlyView,
        );
      case 1:
        return YearlyCalendarView(
          onBottomSheetHeightChanged: widget.onBottomSheetHeightChanged,
          onBottomSheetPageChanged: widget.onBottomSheetPageChanged,
          onMonthTap: _navigateToMonthlyView,
        );
      case 2:
        return ListRecordsView();
      // case 3:
      //   return HistoryRecordsView();
      default:
        return MontlyCalendarView(
          onBottomSheetHeightChanged: widget.onBottomSheetHeightChanged,
          onBottomSheetPageChanged: widget.onBottomSheetPageChanged,
          initialFocusedMonth: _selectedMonthForMonthlyView,
        );
    }
  }

  Widget _buildTabSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // 슬라이딩 선택 표시
            AnimatedBuilder(
              animation: _tabAnimation,
              builder: (context, child) {
                return AnimatedPositioned(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: _currentTabIndex * 75.0, // 각 탭의 대략적인 너비
                  child: Container(
                    width: 75.0,
                    height: 35,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                );
              },
            ),
            // 탭 버튼들
            Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  _tabLabels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final label = entry.value;
                    return _buildTabButton(label, index);
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabSelected(index),
      child: Container(
        width: 75.0,
        height: 35,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
