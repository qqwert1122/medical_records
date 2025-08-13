// calendar_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/calendar/widgets/calendar_bottom_sheet_handle.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';

class CalendarBottomSheet extends StatefulWidget {
  final double bottomSheetHeight;
  final DateTime? selectedDay;
  final Function(double) onHeightChanged;
  final Function(DateTime) onDateChanged;

  const CalendarBottomSheet({
    Key? key,
    required this.bottomSheetHeight,
    required this.selectedDay,
    required this.onHeightChanged,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  State<CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<CalendarBottomSheet> {
  List<Map<String, dynamic>> _dayRecords = [];
  Map<String, dynamic>? _selectedRecord;
  List<Map<String, dynamic>> _recordImages = [];
  bool _isLoading = false;
  bool _showDetail = false;

  // 드래그 관련 변수
  double _dragStartHeight = 0;
  bool _isDraggingHandle = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedDay != null) {
      _loadDayRecords();
    }
  }

  @override
  void didUpdateWidget(CalendarBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay != oldWidget.selectedDay &&
        widget.selectedDay != null) {
      _loadDayRecords();
      setState(() {
        _showDetail = false;
        _selectedRecord = null;
        _recordImages = [];
      });
    }
  }

  Future<void> _loadDayRecords() async {
    if (widget.selectedDay == null) return;

    setState(() => _isLoading = true);

    try {
      // 로컬 시간 기준으로 날짜 범위 설정
      final startOfDay = DateTime(
        widget.selectedDay!.year,
        widget.selectedDay!.month,
        widget.selectedDay!.day,
      );
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

      final records = await DatabaseService().getRecordsByDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (mounted) {
        setState(() {
          _dayRecords =
              records.toList()..sort((a, b) {
                // 최신 기록이 위로 오도록 정렬
                final aDate = DateTime.parse(b['start_date']).toLocal();
                final bDate = DateTime.parse(a['start_date']).toLocal();
                return aDate.compareTo(bDate);
              });
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

  Future<void> _loadRecordImages(int recordId) async {
    try {
      final images = await DatabaseService().getImages(recordId);
      if (mounted) {
        setState(() {
          _recordImages = images;
        });
      }
    } catch (e) {
      print('이미지 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: 0,
      height: screenHeight * widget.bottomSheetHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: context.hp(1)),
            CalendarBottomSheetHandle(
              currentHeight: widget.bottomSheetHeight,
              onHeightChanged: widget.onHeightChanged,
              isDetailView: _showDetail,
            ),
            SizedBox(height: context.hp(2)),

            if (widget.bottomSheetHeight > 0.1 && widget.selectedDay != null)
              Expanded(
                child:
                    _showDetail && _selectedRecord != null
                        ? _buildRecordDetail()
                        : _buildRecordsList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateHeader(widget.selectedDay!),
                style: AppTextStyle.subTitle,
              ),
              if (_dayRecords.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.wp(2),
                    vertical: context.hp(0.3),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_dayRecords.length}개 기록',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: context.hp(2)),
        // 레코드 목록
        Expanded(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  )
                  : _dayRecords.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: context.hp(1)),
                        Text(
                          '등록된 기록이 없습니다',
                          style: AppTextStyle.body.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: context.wp(4)),
                    itemCount: _dayRecords.length,
                    itemBuilder: (context, index) {
                      final record = _dayRecords[index];
                      return _buildRecordItem(record);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final color = Color(int.parse(record['color']));
    final localDate = DateTime.parse(record['start_date']).toLocal();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService().getImages(record['record_id']),
      builder: (context, snapshot) {
        final images = snapshot.data ?? [];

        return GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            await _loadRecordImages(record['record_id']);
            setState(() {
              _selectedRecord = record;
              _showDetail = true;
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: context.hp(1.5)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await _loadRecordImages(record['record_id']);
                  setState(() {
                    _selectedRecord = record;
                    _showDetail = true;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(context.wp(3.5)),
                  child: Row(
                    children: [
                      // 왼쪽 컨텐츠
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상단: 색깔 / 증상 이름 / 스팟 이름
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: context.wp(3)),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildChip(
                                        record['symptom_name'] ?? '증상 없음',
                                        Colors.pinkAccent,
                                        Colors.white,
                                      ),
                                      _buildChip(
                                        record['spot_name'] ?? '부위 없음',
                                        Colors.grey[200]!,
                                        Colors.grey[700]!,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // 하단: 메모
                            if (record['memo'] != null &&
                                record['memo'].toString().trim().isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: context.hp(1)),
                                child: Text(
                                  record['memo'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 오른쪽: 시간과 이미지 스택
                      SizedBox(width: context.wp(2)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 시간 표시
                          Text(
                            '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          // 이미지 스택
                          if (images.isNotEmpty) ...[
                            SizedBox(height: context.hp(0.5)),
                            _buildImageStack(images),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 이미지 스택 위젯 추가
  Widget _buildImageStack(List<Map<String, dynamic>> images) {
    final displayCount = images.length > 3 ? 3 : images.length;
    final remainingCount = images.length - displayCount;

    return Container(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 이미지들을 스택으로 표시 (최대 3개)
          ...List.generate(displayCount, (index) {
            final reversedIndex = displayCount - 1 - index;
            final image = images[reversedIndex];
            final offset = index * 4.0;

            return Positioned(
              top: offset,
              left: offset,
              child: Container(
                width: 52 - (index * 4),
                height: 52 - (index * 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(image['image_url']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 20,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
          // +n 표시 (3개 이상일 때)
          if (remainingCount > 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordDetail() {
    if (_selectedRecord == null) return Container();

    final color = Color(int.parse(_selectedRecord!['color']));
    final localDate = DateTime.parse(_selectedRecord!['start_date']).toLocal();

    return Column(
      children: [
        // 뒤로가기 버튼과 제목
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.wp(2)),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showDetail = false;
                    _selectedRecord = null;
                    _recordImages = [];
                  });
                },
              ),
              Expanded(
                child: Text(
                  '기록 상세',
                  style: AppTextStyle.subTitle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.wp(4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 기본 정보 카드
                Container(
                  padding: EdgeInsets.all(context.wp(4)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: context.wp(4)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedRecord!['symptom_name'] ?? '증상 없음',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _selectedRecord!['spot_name'] ?? '부위 없음',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_selectedRecord!['memo'] != null &&
                          _selectedRecord!['memo']
                              .toString()
                              .trim()
                              .isNotEmpty) ...[
                        SizedBox(height: context.hp(2)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(context.wp(3)),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '메모',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                _selectedRecord!['memo'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 이미지 갤러리
                if (_recordImages.isNotEmpty) ...[
                  SizedBox(height: context.hp(2)),
                  _buildImageGallery(),
                ],

                // 상세 정보
                SizedBox(height: context.hp(2)),
                Container(
                  padding: EdgeInsets.all(context.wp(4)),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        '기록일',
                        _formatDateTime(localDate),
                      ),
                      if (_selectedRecord!['end_date'] != null)
                        _buildInfoRow(
                          Icons.event_available,
                          '종료일',
                          _formatDateTime(
                            DateTime.parse(
                              _selectedRecord!['end_date'],
                            ).toLocal(),
                          ),
                        ),
                      _buildInfoRow(
                        Icons.category,
                        '타입',
                        _getTypeLabel(_selectedRecord!['type']),
                      ),
                      _buildInfoRow(
                        Icons.tag,
                        '기록 ID',
                        '#${_selectedRecord!['record_id']}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.hp(1)),
          child: Row(
            children: [
              Icon(Icons.photo_library, size: 20, color: Colors.grey[700]),
              SizedBox(width: 8),
              Text(
                '사진 (${_recordImages.length})',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Container(
          height: context.hp(20),
          child: CarouselSlider(
            options: CarouselOptions(
              height: context.hp(20),
              enlargeCenterPage: true,
              enableInfiniteScroll: _recordImages.length > 1,
              viewportFraction: 0.85,
              enlargeFactor: 0.2,
            ),
            items:
                _recordImages.map((image) {
                  final imagePath = image['image_url'] as String;
                  return GestureDetector(
                    onTap:
                        () => _showFullScreenImage(
                          _recordImages,
                          _recordImages.indexOf(image),
                        ),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(0.8)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday % 7]})';
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'INITIAL':
        return '초기';
      case 'PROGRESS':
        return '진행중';
      case 'TREATMENT':
        return '치료중';
      case 'COMPLETE':
        return '완료';
      default:
        return type ?? '-';
    }
  }

  void _showFullScreenImage(
    List<Map<String, dynamic>> images,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FullScreenImageGallery(
              images: images,
              initialIndex: initialIndex,
            ),
      ),
    );
  }
}

// 전체화면 이미지 갤러리
class FullScreenImageGallery extends StatelessWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  const FullScreenImageGallery({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final imagePath = images[index]['image_url'] as String;
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(imagePath)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: imagePath),
              );
            },
            itemCount: images.length,
            loadingBuilder:
                (context, event) => Center(
                  child: CircularProgressIndicator(
                    value:
                        event == null
                            ? 0
                            : event.cumulativeBytesLoaded /
                                (event.expectedTotalBytes ?? 1),
                    color: Colors.white,
                  ),
                ),
            pageController: PageController(initialPage: initialIndex),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (images.length > 1)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${initialIndex + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
