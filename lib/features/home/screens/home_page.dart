import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/components/summary_card.dart';
import 'package:medical_records/components/navigation_drawer.dart'
    as CustomDrawer;
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
  final Function(bool)? onDrawerStateChanged;

  const HomePage({super.key, this.onNavigateToTab, this.onDrawerStateChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _recentRecords = [];
  List<Map<String, dynamic>> _recentHistory = [];
  List<Map<String, dynamic>> _activeRecordsList = [];
  List<Map<String, dynamic>> _treatmentRecordsList = [];
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Analytics 대시보드 데이터
  int _activeRecords = 0;
  int _treatmentRecords = 0;

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
      // 최근 히스토리 (최근 10개)
      final recentHistory = await DatabaseService().getRecentTimeline(
        limit: 10,
      );

      // Analytics 데이터 계산
      await _loadAnalyticsData();

      if (mounted) {
        setState(() {
          _recentRecords = recentRecords;
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
      final activeRecords =
          records.where((r) => r['end_date'] == null).toList();
      _activeRecords = activeRecords.length;
      _activeRecordsList = activeRecords;

      // 치료중 record 계산 (진행중이면서 최근에 TREATMENT 이벤트가 있는 것들)
      await _calculateTreatmentRecords(activeRecords);
    } catch (e) {
      debugPrint('Analytics 데이터 로드 실패: $e');
      _activeRecords = 0;
      _activeRecordsList = [];
      _treatmentRecords = 0;
      _treatmentRecordsList = [];
    }
  }

  Future<void> _calculateTreatmentRecords(
    List<Map<String, dynamic>> activeRecords,
  ) async {
    try {
      List<Map<String, dynamic>> treatmentRecords = [];

      for (final record in activeRecords) {
        final recordId = record['record_id'];
        final histories = await DatabaseService().getHistories(recordId);

        // TREATMENT 이벤트가 있는지 확인
        final hasTreatment = histories.any(
          (h) => h['event_type'] == 'TREATMENT',
        );
        if (hasTreatment) {
          treatmentRecords.add(record);
        }
      }

      _treatmentRecords = treatmentRecords.length;
      _treatmentRecordsList = treatmentRecords;
    } catch (e) {
      debugPrint('치료중 레코드 계산 실패: $e');
      _treatmentRecords = 0;
      _treatmentRecordsList = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      // drawer: CustomDrawer.NavigationDrawer(
      //   onAddRecord: _showAddRecordForm,
      //   onNavigateToRecordsList: _navigateToRecordsList,
      // ),
      // onDrawerChanged: (isOpened) {
      //   widget.onDrawerStateChanged?.call(isOpened);
      // },
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        // leading: IconButton(
        //   onPressed: () {
        //     _scaffoldKey.currentState?.openDrawer();
        //     widget.onDrawerStateChanged?.call(true);
        //   },
        //   icon: Icon(Icons.menu, color: AppColors.textPrimary),
        // ),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards 섹션
                      _buildSummaryCards(),
                      SizedBox(height: context.hp(2)),

                      // 진행중 섹션
                      ProgressSection(
                        activeRecords: _activeRecords,
                        activeRecordsList: _activeRecordsList,
                      ),
                      SizedBox(height: context.hp(2)),

                      // 연간 심플 캘린더 섹션
                      YearlySimpleCalendar(currentYear: DateTime.now()),

                      SizedBox(height: context.hp(15)),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: '진행중',
            value: '${_activeRecords.toString()}건',
            icon: LucideIcons.circleDashed,
            color: Colors.blueAccent,
            avatars: _activeRecordsList,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: SummaryCard(
            title: '치료중',
            value:
                _treatmentRecords == 0
                    ? '-'
                    : '${_treatmentRecords.toString()}건',
            icon: LucideIcons.heart,
            color: Colors.pinkAccent,
            avatars: _treatmentRecordsList,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      {
        'icon': LucideIcons.plus,
        'label': '새 기록',
        'color': Colors.green,
        'onTap': _showAddRecordForm,
      },
      {
        'iconAsset': 'assets/icons/image.png',
        'label': '이미지',
        'color': Colors.indigoAccent,
        'onTap': () => widget.onNavigateToTab?.call(2),
      },
      {
        'iconAsset': 'assets/icons/stat.png',
        'label': '통계',
        'color': Colors.pinkAccent,
        'onTap': () => widget.onNavigateToTab?.call(3),
      },
      {
        'icon': LucideIcons.clock,
        'label': '히스토리',
        'color': Colors.orange,
        'onTap': () => widget.onNavigateToTab?.call(1), // 기록 페이지의 히스토리 탭
      },
      {
        'icon': LucideIcons.list,
        'label': '기록',
        'color': Colors.blue,
        'onTap': () => widget.onNavigateToTab?.call(1),
      },
      {
        'icon': LucideIcons.settings,
        'label': '설정',
        'color': Colors.grey,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingPage()),
            ),
      },
    ];

    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: menuItems.length,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return Container(
            width: 100,
            margin: EdgeInsets.only(
              right: index < menuItems.length - 1 ? 12 : 0,
            ),
            child: _buildMenuButton(
              icon: item['icon'] as IconData?,
              iconAsset: item['iconAsset'] as String?,
              label: item['label'] as String,
              color: item['color'] as Color,
              onTap: item['onTap'] as VoidCallback,
            ),
          );
        },
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
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconAsset != null
                ? Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                  ),
                  child: Image.asset(iconAsset, width: 32, height: 32),
                )
                : Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
            SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyle.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
