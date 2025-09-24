import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/features/calendar/widgets/record_list_memos_widget.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/utils/time_format.dart';
import 'package:path/path.dart';

class CalendarRecordsList extends StatefulWidget {
  final List<Map<String, dynamic>> dayRecords;
  final Map<int, List<Map<String, dynamic>>> recordImages;
  final Map<int, List<String>> recordMemos;
  final bool isLoading;
  final Function(Map<String, dynamic>) onRecordTap;
  final Function(double) onHeightChanged;
  final Map<int, List<Map<String, dynamic>>> histories;

  const CalendarRecordsList({
    Key? key,
    required this.dayRecords,
    required this.recordImages,
    required this.recordMemos,
    required this.isLoading,
    required this.onRecordTap,
    required this.onHeightChanged,
    required this.histories,
  }) : super(key: key);

  @override
  State<CalendarRecordsList> createState() => _CalendarRecordsListState();
}

class _CalendarRecordsListState extends State<CalendarRecordsList> {
  final Map<int, Timer> _timers = {};
  final Map<int, bool> _showStartStates = {};

  @override
  void initState() {
    super.initState();
    _initializeTimers();
  }

  void _initializeTimers() {
    for (var record in widget.dayRecords) {
      final recordId = record['record_id'];
      final endDate = record['end_date'];
      _showStartStates[recordId] = true;

      // 종료 시간이 있는 경우에만 타이머 설정
      if (endDate != null) {
        _timers[recordId] = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (mounted) {
            setState(() {
              _showStartStates[recordId] =
                  !(_showStartStates[recordId] ?? true);
            });
          }
        });
      }
    }
  }

  @override
  void didUpdateWidget(CalendarRecordsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // dayRecords가 변경되면 타이머 재초기화
    if (widget.dayRecords != oldWidget.dayRecords) {
      _clearTimers();
      _initializeTimers();
    }
  }

  void _clearTimers() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _showStartStates.clear();
  }

  @override
  void dispose() {
    _clearTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: context.hp(1)),
        Expanded(
          child:
              widget.isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  )
                  : widget.dayRecords.isEmpty
                  ? Center(
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
                          style: AppTextStyle.body.copyWith(
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: context.paddingHorizSM,
                    itemCount: widget.dayRecords.length,
                    itemBuilder: (context, index) {
                      final sortedRecords = List<Map<String, dynamic>>.from(
                        widget.dayRecords,
                      )..sort((a, b) {
                        // 1. status가 PROGRESS인 것 우선 (PROGRESS가 없으면 end_date가 null인 것)
                        final aInProgress = a['end_date'] == null;
                        final bInProgress = b['end_date'] == null;
                        if (aInProgress != bInProgress) {
                          return aInProgress ? -1 : 1;
                        }

                        // 2. start_date가 이른 것 우선
                        final aStartDate = DateTime.parse(a['start_date']);
                        final bStartDate = DateTime.parse(b['start_date']);
                        final dateComparison = aStartDate.compareTo(bStartDate);
                        if (dateComparison != 0) return dateComparison;

                        // 3. symptom_name ASC
                        final symptomComparison = (a['symptom_name'] as String)
                            .compareTo(b['symptom_name'] as String);
                        if (symptomComparison != 0) return symptomComparison;

                        // 4. spot_name ASC
                        final aSpotName = a['spot_name'] ?? '';
                        final bSpotName = b['spot_name'] ?? '';
                        return aSpotName.compareTo(bSpotName);
                      });

                      final record = sortedRecords[index];
                      return _buildRecordItem(context, record);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildRecordItem(BuildContext context, Map<String, dynamic> record) {
    final recordId = record['record_id'];
    final color = Color(int.parse(record['color']));
    final String startDate = record['start_date'];
    final String? endDate = record['end_date'];

    final images = widget.recordImages[recordId] ?? [];
    final memos = widget.recordMemos[recordId] ?? [];
    final showStart = _showStartStates[recordId] ?? true;

    final bool isComplete = record['end_date'] != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onRecordTap(record);
        widget.onHeightChanged(0.93);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: context.hp(1)),
        padding: context.paddingHorizXS,
        decoration: BoxDecoration(
          color: isComplete ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이템과 사진
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 색깔 바, 증상 이름, 부위 이름, 뱃지
                Row(
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
                              record['symptom_name'],
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
                            endDate != null
                                ? _buildAnimatedTimeBadge(
                                  startDate,
                                  endDate,
                                  showStart,
                                )
                                : _buildTimeRow(
                                  '시작',
                                  TimeFormat.getDate(startDate),
                                ),

                            _buildStatusBadge(record),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                _buildImageStack(images),
              ],
            ),
            if (memos.isNotEmpty) ...[
              SizedBox(height: context.hp(1)),
              RecordListMemosWidget(memos: memos),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> record) {
    final endDate = record['end_date'];
    final recordId = record['record_id'];
    final histories = widget.histories[recordId] ?? [];

    // 상태 판단
    String status;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (endDate != null) {
      // 1. 종료된 경우
      status = '종료';
      backgroundColor = AppColors.backgroundSecondary;
      textColor = AppColors.textPrimary;
      icon = LucideIcons.checkCircle;
    } else {
      // end_date가 null인 경우
      final treatmentCount =
          histories.where((h) => h['event_type'] == 'TREATMENT').length;

      if (treatmentCount > 0) {
        // 2. 치료중인 경우
        status = '치료중';
        backgroundColor = Colors.pinkAccent;
        textColor = AppColors.white;
        icon = LucideIcons.heart; // 또는 원하는 치료 관련 아이콘
      } else {
        // 3. 진행중인 경우
        status = '진행중';
        backgroundColor = Colors.blueAccent;
        textColor = AppColors.white;
        icon = LucideIcons.circleDashed;
      }
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

  Widget _buildAnimatedTimeBadge(
    String startDate,
    String? endDate,
    bool showStart,
  ) {
    final _startDate = TimeFormat.getDate(startDate);
    final _endDate = endDate != null ? TimeFormat.getDate(endDate) : '-';

    return SizedBox(
      height: 20, // 고정 높이로 레이아웃 안정화
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isIncoming = child.key == ValueKey(showStart ? 'start' : 'end');

          if (isIncoming) {
            // 들어오는 애니메이션: 위에서 아래로
            final inAnimation = Tween<Offset>(
              begin: const Offset(0.0, -1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return SlideTransition(
              position: inAnimation,
              child: FadeTransition(opacity: animation, child: child),
            );
          } else {
            // 나가는 애니메이션: 아래로 사라짐
            final outAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

            return SlideTransition(
              position: outAnimation,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
                child: child,
              ),
            );
          }
        },
        child:
            showStart
                ? _buildTimeRow('시작', _startDate, key: const ValueKey('start'))
                : _buildTimeRow('종료', _endDate, key: const ValueKey('end')),
      ),
    );
  }

  Widget _buildTimeRow(String label, String time, {Key? key}) {
    return Container(
      key: key,
      child: Row(
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
            style: AppTextStyle.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
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
}
