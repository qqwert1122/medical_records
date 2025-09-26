import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/features/settings/screens/setting_page.dart';
import 'package:medical_records/features/analysis/screens/analysis_page.dart';
import 'package:medical_records/features/analysis/widgets/summary_card.dart';
import 'package:medical_records/features/images/screens/images_page.dart';
import 'package:medical_records/features/history/screens/history_page.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';

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
      // 최근 이미지들 (최근 6개)
      final recentImages = await DatabaseService().getRecentImages(limit: 6);
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
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Analytics 대시보드
                      _buildAnalyticsDashboard(),
                      SizedBox(height: 24),

                      // 최근 기록 리스트
                      _buildRecentRecordsSection(),
                      SizedBox(height: 24),

                      // 최근 히스토리 섹션
                      _buildRecentHistorySection(),
                      SizedBox(height: 24),

                      // 최근 이미지 섹션
                      _buildRecentImagesSection(),
                    ],
                  ),
                ),
              ),
    );
  }

  // Analytics 대시보드
  Widget _buildAnalyticsDashboard() {
    return Card(
      elevation: 2,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 30일 통계',
              style: AppTextStyle.subTitle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            _buildSummaryCards(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToAnalysis(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '통계 보기',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToHistory(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '히스토리',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: '전체 기록',
                value: '$_totalRecords건',
                icon: LucideIcons.galleryVerticalEnd,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: '진행 중',
                value: '$_activeRecords건',
                icon: LucideIcons.circleDashed,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: '완료됨',
                value: '$_completedRecords건',
                icon: LucideIcons.checkCircle,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: '평균 기간',
                value: '${_averageDuration.toStringAsFixed(1)}일',
                icon: LucideIcons.timer,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 최근 기록 섹션
  Widget _buildRecentRecordsSection() {
    return Card(
      elevation: 2,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 기록',
              style: AppTextStyle.subTitle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            _recentRecords.isEmpty
                ? Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '최근 기록이 없습니다',
                      style: AppTextStyle.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
                : Column(
                  children:
                      _recentRecords.map((record) {
                        return _buildRecentRecordItem(record);
                      }).toList(),
                ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToRecordsList(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '더 보기',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecordItem(Map<String, dynamic> record) {
    final startDate = DateTime.parse(record['start_date']);
    final endDate =
        record['end_date'] != null ? DateTime.parse(record['end_date']) : null;
    final color = Color(int.parse(record['color']));

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['symptom_name'] ?? '기록',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  endDate != null
                      ? '${DateFormat('MM.dd').format(startDate)} - ${DateFormat('MM.dd').format(endDate)}'
                      : '${DateFormat('MM.dd').format(startDate)} - 진행중',
                  style: AppTextStyle.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (endDate == null)
            Icon(FontAwesomeIcons.play, size: 12, color: AppColors.primary),
        ],
      ),
    );
  }

  // 최근 이미지 섹션
  Widget _buildRecentImagesSection() {
    return Card(
      elevation: 2,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 이미지',
              style: AppTextStyle.subTitle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            _recentImages.isEmpty
                ? Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '최근 이미지가 없습니다',
                      style: AppTextStyle.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
                : Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _recentImages.take(6).length,
                      itemBuilder: (context, index) {
                        return _buildImageItem(_recentImages[index]);
                      },
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToImages(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '더 보기',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(Map<String, dynamic> image) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: _buildImageWidget(image['image_url']),
      ),
    );
  }

  Widget _buildImageWidget(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholderImage();
    }

    // 로컬 파일 경로인지 확인
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    }

    // 네트워크 이미지 시도
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.surface,
      child: Icon(
        FontAwesomeIcons.image,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }

  // 최근 히스토리 섹션
  Widget _buildRecentHistorySection() {
    return Card(
      elevation: 2,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 히스토리',
              style: AppTextStyle.subTitle.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12),
            _recentHistory.isEmpty
                ? Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '최근 히스토리가 없습니다',
                      style: AppTextStyle.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
                : _buildHistoryTimeline(),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '더 보기',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTimeline() {
    return Container(
      height: 400, // 제한된 높이 설정
      child: ListView.builder(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        itemCount: _recentHistory.length,
        itemBuilder: (context, index) {
          final event = _recentHistory[index];
          final eventDate = DateTime.parse(event['date']).toLocal();
          final currentDate = TimeFormat.getDate(event['date']);
          final previousDate =
              index > 0
                  ? TimeFormat.getDate(_recentHistory[index - 1]['date'])
                  : '';

          final color =
              event['type'] == 'symptom'
                  ? Color(int.parse(event['color']))
                  : _getEventTypeColor(event['type']);

          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.2,
            isFirst: index == 0,
            isLast: index == _recentHistory.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 16,
              height: 16,
              indicator: Container(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Icon(
                    _getEventTypeIcon(event),
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              ),
            ),
            beforeLineStyle: LineStyle(
              color: AppColors.backgroundSecondary,
              thickness: 2,
            ),
            afterLineStyle: LineStyle(
              color: AppColors.backgroundSecondary,
              thickness: 2,
            ),
            startChild: Padding(
              padding: EdgeInsets.only(right: 8),
              child:
                  currentDate != previousDate
                      ? Text(
                        TimeFormat.getDate(event['date']),
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      )
                      : SizedBox(height: 0),
            ),
            endChild: Container(
              padding: EdgeInsets.only(left: 12, bottom: 16, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 시간
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event['title'] ?? '기록',
                          style: AppTextStyle.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimeOnly(eventDate),
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  // 부위/증상 정보
                  if (event['subtitle'] != null && event['subtitle'].isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        event['subtitle'],
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // 이벤트 타입 라벨
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getEventTypeLabel(event),
                        style: AppTextStyle.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimeOnly(DateTime date) {
    return '${date.hour}시 ${date.minute}분';
  }

  IconData _getEventTypeIcon(Map<String, dynamic> event) {
    final type = event['type'];
    switch (type) {
      case 'symptom':
        return LucideIcons.alertCircle;
      case 'INITIAL':
        return LucideIcons.circleDashed;
      case 'PROGRESS':
        return LucideIcons.arrowRight;
      case 'TREATMENT':
        return LucideIcons.heart;
      case 'COMPLETE':
        return LucideIcons.checkCircle;
      default:
        return LucideIcons.circle;
    }
  }

  String _getEventTypeLabel(Map<String, dynamic> event) {
    final type = event['type'];
    switch (type) {
      case 'symptom':
        return '증상';
      case 'INITIAL':
        return '증상';
      case 'PROGRESS':
        return '경과';
      case 'TREATMENT':
        return '치료';
      case 'COMPLETE':
        return '완료';
      default:
        return '기록';
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'symptom':
        return Colors.redAccent;
      case 'INITIAL':
        return Colors.redAccent;
      case 'PROGRESS':
        return Colors.blueAccent;
      case 'TREATMENT':
        return Colors.pinkAccent;
      case 'COMPLETE':
        return Colors.green;
      default:
        return AppColors.primary;
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
