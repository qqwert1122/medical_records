import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> records;

      switch (_filterStatus) {
        case 'ONGOING':
          records = await DatabaseService().getOngoingRecords();
          break;
        case 'COMPLETED':
          final db = await DatabaseService().database;
          records = await db.query(
            'records',
            where: 'end_date IS NOT NULL AND deleted_at IS NULL',
            orderBy: 'start_date DESC',
          );
          break;
        default:
          records = await DatabaseService().getRecentRecords(limit: 100);
      }

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 필터 탭바
        _buildFilterTabs(),

        // 기록 리스트
        Expanded(
          child: _isLoading
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
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: _records.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            return _buildRecordItem(_records[index]);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterTab('전체', 'ALL'),
          SizedBox(width: 8),
          _buildFilterTab('진행중', 'ONGOING'),
          SizedBox(width: 8),
          _buildFilterTab('완료', 'COMPLETED'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _filterStatus = status);
        _loadRecords();
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

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final startDate = DateTime.parse(record['start_date']);
    final endDate =
        record['end_date'] != null ? DateTime.parse(record['end_date']) : null;
    final color = Color(int.parse(record['color']));
    final isOngoing = endDate == null;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record['title'] ?? '제목 없음',
                    style: AppTextStyle.subTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isOngoing
                        ? '${DateFormat('yyyy.MM.dd').format(startDate)} ~'
                        : '${DateFormat('yyyy.MM.dd').format(startDate)} ~ ${DateFormat('yyyy.MM.dd').format(endDate!)}',
                    style: AppTextStyle.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOngoing ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOngoing ? '진행중' : '완료',
                style: AppTextStyle.caption.copyWith(
                  color: isOngoing ? Colors.green : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_filterStatus) {
      case 'ONGOING':
        message = '진행중인 기록이 없습니다';
        break;
      case 'COMPLETED':
        message = '완료된 기록이 없습니다';
        break;
      default:
        message = '등록된 기록이 없습니다';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.fileLines,
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
}