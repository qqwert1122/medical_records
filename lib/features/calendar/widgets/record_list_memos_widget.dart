// 4. CalendarRecordsList 클래스 아래에 새 위젯 추가

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';

class RecordListMemosWidget extends StatefulWidget {
  final List<String> memos;

  const RecordListMemosWidget({Key? key, required this.memos})
    : super(key: key);

  @override
  State<RecordListMemosWidget> createState() => _RecordListMemosWidgetState();
}

class _RecordListMemosWidgetState extends State<RecordListMemosWidget> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.memos.length > 1) {
      _timer = Timer.periodic(Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.memos.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        widget.memos[_currentIndex],
        style: AppTextStyle.caption.copyWith(color: AppColors.textSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
