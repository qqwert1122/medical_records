import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/features/calendar/widgets/full_screen_image_gallery.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImagesPage extends StatefulWidget {
  const ImagesPage({super.key});

  @override
  State<ImagesPage> createState() => _ImagesPageState();
}

class _ImagesPageState extends State<ImagesPage> {
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> _spots = [];
  List<Map<String, dynamic>> _symptoms = [];
  List<Map<String, dynamic>> _treatments = [];
  List<Map<String, dynamic>> _images = [];
  Map<String, List<Map<String, dynamic>>> _groupedImages = {};

  int? _selectedSpotId;
  int? _selectedSymptomId;
  int? _selectedTreatmentId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadImages();
  }

  Future<void> _loadFilters() async {
    final spots = await _dbService.getSpots();
    final symptoms = await _dbService.getSymptoms();
    final treatments = await _dbService.getTreatments();

    if (!mounted) return;

    setState(() {
      _spots = [
        {'spot_id': null, 'spot_name': '전체'},
        ...spots,
      ];
      _symptoms = [
        {'symptom_id': null, 'symptom_name': '전체'},
        ...symptoms,
      ];
      _treatments = [
        {'treatment_id': null, 'treatment_name': '전체'},
        ...treatments,
      ];
    });
  }

  Future<void> _loadImages() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // 필터에 따른 records 조회
    final records = await _dbService.getRecords(
      spotId: _selectedSpotId,
      symptomId: _selectedSymptomId,
      treatmentId: _selectedTreatmentId,
    );

    List<Map<String, dynamic>> allImages = [];

    for (var record in records) {
      final histories = await _dbService.getHistories(record['record_id']);

      for (var history in histories) {
        final images = await _dbService.getImages(history['history_id']);

        // 이미지에 메타데이터 추가
        for (var image in images) {
          allImages.add({
            ...image,
            'record_id': record['record_id'],
            'spot_name': record['spot_name'],
            'symptom_name': record['symptom_name'],
            'treatment_name': history['treatment_name'] ?? '',
            'record_date': history['record_date'],
          });
        }
      }
    }

    // 날짜별로 그룹화
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var image in allImages) {
      final date = DateTime.parse(image['record_date']);
      final dateKey = DateFormat('yyyy년 MM월 dd일').format(date);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(image);
    }

    grouped.forEach((key, images) {
      images.sort((b, a) {
        // created_at 기준으로 최신순 정렬
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });
    });

    // 날짜 기준 정렬 (최신 날짜가 위로)
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
          final dateA = DateFormat('yyyy년 MM월 dd일').parse(a);
          final dateB = DateFormat('yyyy년 MM월 dd일').parse(b);
          return dateB.compareTo(dateA);
        });

    Map<String, List<Map<String, dynamic>>> sortedGrouped = {};
    List<Map<String, dynamic>> sortedAllImages = [];
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
      sortedAllImages.addAll(grouped[key]!);
    }

    if (!mounted) return;

    setState(() {
      _images = sortedAllImages;
      _groupedImages = sortedGrouped;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '이미지',
          style: AppTextStyle.title.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 필터 섹션
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                spacing: 10,
                children: [
                  // 필터 초기화 버튼
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (mounted) {
                        setState(() {
                          _selectedSpotId = null;
                          _selectedSymptomId = null;
                          _selectedTreatmentId = null;
                        });
                      }
                      _loadImages();
                    },
                    child: Container(
                      height: 36,
                      width: 36,
                      padding: context.paddingXS,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.filterX,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // 부위별 필터
                  _buildCompactDropdown(
                    label: '부위',
                    value: _selectedSpotId,
                    items: _spots,
                    idKey: 'spot_id',
                    nameKey: 'spot_name',
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      if (mounted) {
                        setState(() {
                          _selectedSpotId = value;
                        });
                      }
                      _loadImages();
                    },
                  ),
                  // 증상별 필터
                  _buildCompactDropdown(
                    label: '증상',
                    value: _selectedSymptomId,
                    items: _symptoms,
                    idKey: 'symptom_id',
                    nameKey: 'symptom_name',
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      if (mounted) {
                        setState(() {
                          _selectedSymptomId = value;
                        });
                      }
                      _loadImages();
                    },
                  ),
                  // 치료유형별 필터
                  _buildCompactDropdown(
                    label: '치료',
                    value: _selectedTreatmentId,
                    items: _treatments,
                    idKey: 'treatment_id',
                    nameKey: 'treatment_name',
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      if (mounted) {
                        setState(() {
                          _selectedTreatmentId = value;
                        });
                      }
                      _loadImages();
                    },
                  ),
                ],
              ),
            ),
          ),
          // 이미지 그리드뷰
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textPrimary,
                      ),
                    )
                    : _images.isEmpty
                    ? Center(
                      child: Text(
                        '이미지가 없습니다',
                        style: AppTextStyle.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: context.hp(10),
                      ),
                      itemCount: _groupedImages.length,
                      itemBuilder: (context, sectionIndex) {
                        final dateKey = _groupedImages.keys.elementAt(
                          sectionIndex,
                        );
                        final sectionImages = _groupedImages[dateKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 날짜 헤더
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    dateKey,
                                    style: AppTextStyle.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${sectionImages.length}장',
                                    style: AppTextStyle.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 이미지 그리드
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: sectionImages.length,
                              itemBuilder: (context, index) {
                                final image = sectionImages[index];
                                final imagePath = image['image_url'];
                                // 전체 이미지 리스트에서의 실제 인덱스 찾기
                                final globalIndex = _images.indexOf(image);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => FullScreenImageGallery(
                                              images: _images,
                                              initialIndex: globalIndex,
                                              reverseOrder: false,
                                            ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    child: Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: AppColors.surface,
                                          child: Icon(
                                            Icons.broken_image,
                                            color: AppColors.textSecondary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    required ValueChanged<int?> onChanged,
  }) {
    // 선택된 아이템의 이름 찾기
    String selectedName = '전체';
    for (var item in items) {
      if (item[idKey] == value) {
        selectedName = item[nameKey];
        break;
      }
    }

    return DropdownButton2<int?>(
      value: value,
      underline: const SizedBox(),
      isDense: true,
      isExpanded: false,
      customButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null ? Colors.pinkAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyle.caption.copyWith(
                fontSize: 14,
                color:
                    value != null ? AppColors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              selectedName,
              style: AppTextStyle.caption.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: value != null ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: value != null ? AppColors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
      items:
          items.map((item) {
            return DropdownMenuItem<int?>(
              value: item[idKey],
              child: Text(
                item[nameKey],
                style: AppTextStyle.caption.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
      onChanged: onChanged,
      dropdownStyleData: DropdownStyleData(
        maxHeight: 300,
        width: null,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        elevation: 0,
        scrollbarTheme: ScrollbarThemeData(
          radius: const Radius.circular(40),
          thickness: WidgetStateProperty.all(4),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
      ),
    );
  }
}
