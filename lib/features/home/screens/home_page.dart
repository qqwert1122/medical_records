import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/components/summary_card.dart';
import 'package:medical_records/features/form/screens/record_form_page.dart';
import 'package:medical_records/features/settings/screens/setting_page.dart';
import 'package:medical_records/features/analysis/screens/analysis_page.dart';
import 'package:medical_records/features/images/screens/images_page.dart';
import 'package:medical_records/features/history/screens/history_page.dart';
import 'package:medical_records/features/home/widgets/analytics_dashboard.dart';
import 'package:medical_records/features/home/widgets/recent_records_section.dart';
import 'package:medical_records/features/home/widgets/recent_history_timeline.dart';
import 'package:medical_records/features/home/widgets/progress_section.dart';
import 'package:medical_records/features/home/widgets/yearly_simple_calendar.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/services/review_service.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomePage({super.key, this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _recentRecords = [];
  List<Map<String, dynamic>> _recentImages = [];
  List<Map<String, dynamic>> _recentHistory = [];
  bool _isLoading = true;

  // Analytics 대시보드 데이터
  int _totalRecords = 0;
  int _activeRecords = 0;
  int _completedRecords = 0;
  double _averageDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 최근 기록들 (최근 5개)
      final recentRecords = await DatabaseService().getRecentRecords(limit: 5);
      // 최근 이미지들 (최근 10개)
      final recentImages = await DatabaseService().getRecentImages(limit: 10);
      // 최근 히스토리 (최근 10개)
      final recentHistory = await DatabaseService().getRecentTimeline(
        limit: 10,
      );

      // Analytics 데이터 계산
      await _loadAnalyticsData();

      if (mounted) {
        setState(() {
          _recentRecords = recentRecords;
          _recentImages = recentImages;
          _recentHistory = recentHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('데이터 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));

      // 최근 30일간의 모든 레코드 조회
      final records = await DatabaseService().getOverlappingRecords(
        startDate: thirtyDaysAgo,
        endDate: now,
      );

      // 기본 통계 계산
      _totalRecords = records.length;
      _activeRecords = records.where((r) => r['end_date'] == null).length;
      _completedRecords = records.where((r) => r['end_date'] != null).length;
      _calculateAverageDuration(records);
    } catch (e) {
      debugPrint('Analytics 데이터 로드 실패: $e');
      _totalRecords = 0;
      _activeRecords = 0;
      _completedRecords = 0;
      _averageDuration = 0;
    }
  }

  void _calculateAverageDuration(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      _averageDuration = 0;
      return;
    }

    double totalDays = 0;
    int validRecords = 0;

    for (final record in records) {
      final startDate = DateTime.parse(record['start_date']);
      final endDate =
          record['end_date'] != null
              ? DateTime.parse(record['end_date'])
              : DateTime.now();

      final duration = endDate.difference(startDate).inDays + 1;
      totalDays += duration;
      validRecords++;
    }

    _averageDuration = validRecords > 0 ? totalDays / validRecords : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          '마이델로지',
          style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => SettingPage()));
            },
            icon: Icon(Icons.settings, color: AppColors.textPrimary),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('데이터 로딩 중...', style: AppTextStyle.body),
                  ],
                ),
              )
              : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressSection(activeRecords: _activeRecords), // 진행중 섹션

                    YearlySimpleCalendar(
                      currentYear: DateTime.now(),
                    ), // 연간 심플 캘린더 섹션
                    // 메뉴 섹션
                    _buildMenuSection(),

                    // 최근 기록 리스트
                    RecentRecordsSection(
                      recentRecords: _recentRecords,
                      onMorePressed: _navigateToRecordsList,
                    ),
                    SizedBox(height: 24),

                    // 최근 히스토리 섹션
                    RecentHistoryTimeline(
                      recentHistory: _recentHistory,
                      onMorePressed: _navigateToHistory,
                    ),

                    SizedBox(height: context.hp(15)),
                  ],
                ),
              ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 이미지 버튼
          Expanded(
            child: _buildMenuButton(
              iconAsset: 'assets/icons/image.png',
              label: '이미지',
              color: Colors.indigoAccent,
              onTap: _navigateToImages,
            ),
          ),
          SizedBox(width: 12),
          // 통계 버튼
          Expanded(
            child: _buildMenuButton(
              iconAsset: 'assets/icons/stat.png',
              label: '통계',
              color: Colors.pinkAccent,
              onTap: _navigateToAnalysis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    IconData? icon,
    String? iconAsset,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          iconAsset != null
              ? Container(
                padding: EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: Image.asset(iconAsset, width: 80, height: 80),
              )
              : Icon(icon, color: color, size: 24),
          SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyle.subTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRecordForm() async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: RecordFormPage(selectedDate: DateTime.now()),
          ),
    );

    if (result == true) {
      await _loadData();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ReviewService.requestReviewIfEligible(context);
      });
    }
  }

  // 네비게이션 메서드들
  void _navigateToAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnalysisPage()),
    );
  }

  void _navigateToRecordsList() {
    // 메인 네비게이션의 리스트 탭(인덱스 2)으로 이동
    HapticFeedback.lightImpact();
    widget.onNavigateToTab?.call(2);
  }

  void _navigateToImages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImagesPage()),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryPage()),
    );
  }
}
