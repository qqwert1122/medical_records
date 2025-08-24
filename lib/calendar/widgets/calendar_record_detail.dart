import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medical_records/calendar/widgets/full_screen_image_gallery.dart';
import 'package:medical_records/calendar/widgets/record_detail_info.dart';
import 'package:medical_records/calendar/widgets/record_detail_horiz_time_line.dart';
import 'package:medical_records/calendar/widgets/record_detail_image_widget.dart';
import 'package:medical_records/calendar/widgets/record_detail_time_line.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class CalendarRecordDetail extends StatefulWidget {
  final Map<String, dynamic> record;
  final List<Map<String, dynamic>> histories;
  final List<Map<String, dynamic>> images;
  final List<String> memos;
  final VoidCallback onBackPressed;
  final int pageIndex;
  final VoidCallback? onDataUpdated;

  const CalendarRecordDetail({
    super.key,
    required this.record,
    required this.histories,
    required this.images,
    required this.memos,
    required this.onBackPressed,
    required this.pageIndex,
    this.onDataUpdated,
  });

  @override
  State<CalendarRecordDetail> createState() => _CalendarRecordDetailState();
}

class _CalendarRecordDetailState extends State<CalendarRecordDetail> {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface),
      child: Stack(
        children: [
          // 컨텐츠
          SingleChildScrollView(
            // padding: context.paddingHorizSM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 가로 타임라인
                RecordDetailHorizTimeLine(histories: widget.histories),
                SizedBox(height: context.hp(1)),

                // 이미지 갤러리
                if (widget.images.isNotEmpty) ...[
                  RecordDetailImageWidget(
                    histories: widget.histories,
                    images: widget.images,
                    onImageTap: _showFullScreenImage,
                  ),
                ],
                SizedBox(height: context.hp(1)),

                // 타임라인
                RecordDetailTimeline(
                  record: widget.record,
                  histories: widget.histories,
                  images: widget.images,
                  onImageTap: _showFullScreenImage,
                  onHistoryAdded: widget.onDataUpdated,
                ),
                SizedBox(height: context.hp(1)),

                // 상세 정보
                RecordDetailInfo(
                  record: widget.record,
                  onRecordUpdated: widget.onDataUpdated,
                ),
                SizedBox(height: context.hp(20)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
