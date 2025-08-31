import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';
import 'package:medical_records/styles/app_size.dart';
import 'package:medical_records/styles/app_text_style.dart';
import 'package:medical_records/widgets/drag_handle.dart';

/// 재사용 가능한 DateTime 피커 바텀시트
/// 정책:
/// 1) initialDate는 초기 선택 값
/// 2) minDate가 있으면 그 시각(분까지) 이후(>=)만 선택 가능
/// 3) maxDate가 있으면 그 시각(분까지) 이전(<=)만 선택 가능
/// 4) min/max의 한쪽이라도 없으면, 없는 쪽은 initialDate를 기준으로 ±_centerDays 범위를 허용(해당 방향만 대체)
class DateTimePickerBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;

  const DateTimePickerBottomSheet({
    super.key,
    required this.initialDate,
    this.minDate,
    this.maxDate,
  });

  @override
  State<DateTimePickerBottomSheet> createState() =>
      _DateTimePickerBottomSheetState();
}

class _DateTimePickerBottomSheetState extends State<DateTimePickerBottomSheet> {
  // 정책 4: 초기 기준 범위(일) — 필요한 쪽만 대체에 사용
  static const int _centerDays = 365;

  // 계산된 선택 가능 경계
  late DateTime _startBound; // 시작 경계(일 단위 비교는 YMD만 사용, 시분은 경계일 때 제한)
  late DateTime _endBound;

  // 현재 선택 상태
  late DateTime _selectedDate; // 항상 시분 포함
  late int _selectedHour;
  late int _selectedMinute;

  // Day 컬럼 정보
  late int _dayCount; // 아이템 개수
  late int _dayIndex; // 현재 선택 인덱스(= _startBound~선택일 사이 일수)

  // 픽커 컨트롤러들
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();

    // 1) 경계 계산
    _computeBounds();

    // 2) 초기 선택값 클램프
    final initialClamped = _clampToBounds(widget.initialDate);
    _selectedDate = initialClamped;
    _selectedHour = initialClamped.hour;
    _selectedMinute = initialClamped.minute;

    // 3) 경계일이면 시/분 보정
    _enforceTimeOnBoundaryDay();

    // 4) Day 컬럼 길이/인덱스
    _dayCount = _daysBetween(_startBound, _endBound) + 1;
    _dayIndex = _daysBetween(_startBound, _selectedDate);

    // 5) 컨트롤러 초기화
    _dayController = FixedExtentScrollController(initialItem: _dayIndex);
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  // ---------------------------
  // 경계/도우미
  // ---------------------------

  void _computeBounds() {
    // 한쪽 경계가 없으면 initialDate 기준으로 해당 방향을 ±_centerDays로 대체
    final start =
        widget.minDate ??
        widget.initialDate.subtract(Duration(days: _centerDays));
    final end =
        widget.maxDate ?? widget.initialDate.add(Duration(days: _centerDays));

    // 혹시 min > max가 들어오면 swap
    if (start.isAfter(end)) {
      _startBound = end;
      _endBound = start;
    } else {
      _startBound = start;
      _endBound = end;
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _daysBetween(DateTime from, DateTime to) =>
      _dateOnly(to).difference(_dateOnly(from)).inDays;

  bool _isSameDay(DateTime a, DateTime b) => DateUtils.isSameDay(a, b);

  DateTime _clampToBounds(DateTime value) {
    if (value.isBefore(_startBound)) return _startBound;
    if (value.isAfter(_endBound)) return _endBound;
    return value;
  }

  // 현재 선택된 '날짜'가 경계일이면, 시/분을 경계 시/분으로 보정 (클램프)
  void _enforceTimeOnBoundaryDay() {
    // min 경계일
    if (_isSameDay(_selectedDate, _startBound)) {
      if (_selectedHour < _startBound.hour) {
        _selectedHour = _startBound.hour;
      }
      if (_selectedHour == _startBound.hour &&
          _selectedMinute < _startBound.minute) {
        _selectedMinute = _startBound.minute;
      }
    }
    // max 경계일
    if (_isSameDay(_selectedDate, _endBound)) {
      if (_selectedHour > _endBound.hour) {
        _selectedHour = _endBound.hour;
      }
      if (_selectedHour == _endBound.hour &&
          _selectedMinute > _endBound.minute) {
        _selectedMinute = _endBound.minute;
      }
    }

    // 최종 조합
    _selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
      _selectedMinute,
    );
  }

  // 특정 날짜/시/분 조합을 경계에 맞춰 보정하고 컨트롤러도 동기화
  void _applyAndSync(DateTime day, int hour, int minute) {
    _selectedDate = DateTime(day.year, day.month, day.day, hour, minute);
    _selectedDate = _clampToBounds(_selectedDate);

    _selectedHour = _selectedDate.hour;
    _selectedMinute = _selectedDate.minute;

    // 경계일 시/분 보정
    _enforceTimeOnBoundaryDay();

    // 컨트롤러 동기화(현재 값과 다를 때만 점프)
    if (_hourController.selectedItem != _selectedHour) {
      _hourController.jumpToItem(_selectedHour);
    }
    if (_minuteController.selectedItem != _selectedMinute) {
      _minuteController.jumpToItem(_selectedMinute);
    }
  }

  // ---------------------------
  // 빌드
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(40),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: context.paddingHorizSM,
      child: Column(
        children: [
          const DragHandle(),
          _buildTitle(),
          SizedBox(height: context.hp(2)),
          Expanded(
            child: Row(
              children: [
                // 날짜
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text(
                        '날짜',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: context.hp(1)),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _dayController,
                          itemExtent: 50,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.lightImpact();
                            final newDay = _dateOnly(
                              _startBound.add(Duration(days: index)),
                            );
                            setState(() {
                              _dayIndex = index;
                              _applyAndSync(
                                newDay,
                                _selectedHour,
                                _selectedMinute,
                              );
                            });
                          },
                          children: List.generate(_dayCount, (i) {
                            final day = _startBound.add(Duration(days: i));
                            final isToday = _isSameDay(day, DateTime.now());
                            final isSelected = i == _dayIndex;
                            return Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: [
                                  Text(
                                    '${day.year.toString().padLeft(4, '0')}년 ${day.month}월 ${day.day}일',
                                    style: AppTextStyle.body.copyWith(
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isSelected
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (isToday)
                                    Text(
                                      '오늘',
                                      style: AppTextStyle.caption.copyWith(
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.wp(2)),
                // 시간
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        '시',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: context.hp(1)),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _hourController,
                          itemExtent: 50,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.lightImpact();

                            // 경계일이면 허용 범위로 클램프
                            int newHour = index;

                            if (_isSameDay(_selectedDate, _startBound) &&
                                newHour < _startBound.hour) {
                              newHour = _startBound.hour;
                            }
                            if (_isSameDay(_selectedDate, _endBound) &&
                                newHour > _endBound.hour) {
                              newHour = _endBound.hour;
                            }

                            setState(() {
                              _applyAndSync(
                                _dateOnly(_selectedDate),
                                newHour,
                                _selectedMinute,
                              );
                            });
                          },
                          children: List.generate(24, (h) {
                            final isSelected = _selectedHour == h;
                            return Center(
                              child: Text(
                                h.toString().padLeft(2, '0'),
                                style: AppTextStyle.body.copyWith(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.wp(2)),
                // 분
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        '분',
                        style: AppTextStyle.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: context.hp(1)),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _minuteController,
                          itemExtent: 50,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.lightImpact();

                            int newMinute = index;

                            // 경계일 + 경계시간이면 분 제한
                            final onMinBoundaryHour =
                                _isSameDay(_selectedDate, _startBound) &&
                                _selectedHour == _startBound.hour;
                            final onMaxBoundaryHour =
                                _isSameDay(_selectedDate, _endBound) &&
                                _selectedHour == _endBound.hour;

                            if (onMinBoundaryHour &&
                                newMinute < _startBound.minute) {
                              newMinute = _startBound.minute;
                            }
                            if (onMaxBoundaryHour &&
                                newMinute > _endBound.minute) {
                              newMinute = _endBound.minute;
                            }

                            setState(() {
                              _applyAndSync(
                                _dateOnly(_selectedDate),
                                _selectedHour,
                                newMinute,
                              );
                            });
                          },
                          children: List.generate(60, (m) {
                            final isSelected = _selectedMinute == m;
                            return Center(
                              child: Text(
                                m.toString().padLeft(2, '0'),
                                style: AppTextStyle.body.copyWith(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildButtons(),
          SizedBox(height: context.hp(1)),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      '날짜 선택',
      style: AppTextStyle.subTitle.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '취소',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(width: context.wp(4)),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(_selectedDate);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '확인',
              style: AppTextStyle.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
