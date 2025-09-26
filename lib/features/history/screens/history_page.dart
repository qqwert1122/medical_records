import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:io';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _timelineEvents = [];
  bool _isLoading = true;
  String _filterType = 'ALL'; // ALL, SYMPTOMS, TREATMENTS

  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }

  Future<void> _loadTimelineData() async {
    setState(() => _isLoading = true);
    try {
      final events = await DatabaseService().getGlobalTimeline(filterType: _filterType);
      if (mounted) {
        setState(() {
          _timelineEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('타임라인 데이터 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          '전체 히스토리',
          style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // 필터 탭바
          _buildFilterTabs(),

          // 타임라인
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('히스토리 로딩 중...', style: AppTextStyle.body),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTimelineData,
                    child: _timelineEvents.isEmpty
                        ? _buildEmptyState()
                        : _buildTimeline(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterTab('전체', 'ALL'),
          SizedBox(width: 8),
          _buildFilterTab('증상', 'SYMPTOMS'),
          SizedBox(width: 8),
          _buildFilterTab('치료', 'TREATMENTS'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String type) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = type);
        _loadTimelineData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
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

  Widget _buildTimeline() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _timelineEvents.length,
      itemBuilder: (context, index) {
        final event = _timelineEvents[index];
        final eventDate = DateTime.parse(event['date']).toLocal();
        final currentDate = TimeFormat.getDate(event['date']);
        final previousDate = index > 0
            ? TimeFormat.getDate(_timelineEvents[index - 1]['date'])
            : '';

        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.25,
          isFirst: index == 0,
          isLast: index == _timelineEvents.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            height: 20,
            indicator: Container(
              decoration: BoxDecoration(
                color: event['type'] == 'symptom'
                    ? Color(int.parse(event['color']))
                    : _getEventTypeColor(event['type']),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getEventTypeIcon(event),
                  color: Colors.white,
                  size: 12,
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
            padding: EdgeInsets.only(right: 16),
            child: currentDate != previousDate
                ? Text(
                    currentDate,
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  )
                : SizedBox(height: 0),
          ),
          endChild: Container(
            padding: EdgeInsets.only(left: 15, bottom: 20, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이벤트 제목과 시간
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event['title'] ?? '기록',
                        style: AppTextStyle.subTitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _formatTimeOnly(eventDate),
                      style: AppTextStyle.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // 서브타이틀 (부위 정보 또는 증상 정보)
                if (event['subtitle'] != null && event['subtitle'].isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      event['subtitle'],
                      style: AppTextStyle.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                // 메모가 있는 경우 표시
                if (event['memo'] != null && event['memo'].toString().trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event['memo'],
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                // 이벤트 타입 라벨
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event['type']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getEventTypeLabel(event),
                      style: AppTextStyle.caption.copyWith(
                        color: _getEventTypeColor(event['type']),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_filterType) {
      case 'SYMPTOMS':
        message = '증상 기록이 없습니다';
        break;
      case 'TREATMENTS':
        message = '치료 기록이 없습니다';
        break;
      default:
        message = '히스토리가 없습니다';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clock,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyle.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatTimeOnly(DateTime date) {
    return '${date.hour}시 ${date.minute}분';
  }

  String _getEventTypeLabel(Map<String, dynamic> event) {
    final type = event['type'];

    switch (type) {
      case 'symptom':
        return '증상 시작';
      case 'INITIAL':
        return '증상 시작';
      case 'PROGRESS':
        return '진행 경과';
      case 'TREATMENT':
        return '치료';
      case 'COMPLETE':
        return '증상 종료';
      default:
        return type ?? '기록';
    }
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
}