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
}
