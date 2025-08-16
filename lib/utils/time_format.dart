class TimeFormat {
  static String getRelativeTime(String? dateTimeString) {
    if (dateTimeString == null) return '';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return '방금 전';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks}주 전';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months}개월 전';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years}년 전';
      }
    } catch (e) {
      return '미사용';
    }
  }

  static String getAbsoluteAmPm(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dt = DateTime.parse(dateTimeString);
      return _formatAmPm(dt);
    } catch (e) {
      return '미사용';
    }
  }

  static String formatAmPm(DateTime? dt) {
    if (dt == null) return '';
    return _formatAmPm(dt);
  }

  static String getRelativeOrAbsoluteAmPm(
    String? dateTimeString, {
    Duration absoluteAfter = const Duration(days: 7),
  }) {
    if (dateTimeString == null) return '';
    try {
      final dt = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff >= absoluteAfter) {
        return _formatAmPm(dt);
      }
      return getRelativeTime(dateTimeString);
    } catch (e) {
      return '미사용';
    }
  }

  static String _formatAmPm(DateTime dt) {
    final ampm = dt.hour < 12 ? '오전' : '오후';
    final hour12 = (dt.hour % 12 == 0) ? 12 : (dt.hour % 12);
    final mm = dt.minute.toString().padLeft(2, '0');
    // 월/일은 한국식 표기에서 보통 0패딩 없이 씁니다.
    return '${dt.year}년 ${dt.month}월 ${dt.day}일 $ampm ${hour12.toString().padLeft(2, '0')}:$mm';
  }
}
