// lib/utils/link_launcher.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL 열기 유틸
/// - 기본: 외부 브라우저 → 실패 시 인앱 브라우저 → 그래도 실패면 스낵바 + 복사 액션
/// - true/false로 성공 여부 반환
class LinkLauncher {
  LinkLauncher._();

  static Future<bool> open(
    BuildContext context,
    String url, {
    bool haptic = true,
    LaunchMode primary = LaunchMode.externalApplication,
    LaunchMode secondary = LaunchMode.inAppBrowserView,
    String? failMessage, // 실패 메시지 커스텀
    bool showSnackBarOnFail = true,
    bool copyUrlOnFail = true,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (showSnackBarOnFail) {
        _showFailSnackBar(context, '잘못된 링크입니다.', url, copyUrlOnFail);
      }
      return false;
    }

    if (haptic) HapticFeedback.lightImpact();

    try {
      // 1) 외부 브라우저
      if (await launchUrl(uri, mode: primary)) return true;
      // 2) 인앱 브라우저
      if (await launchUrl(uri, mode: secondary)) return true;
    } on PlatformException catch (e) {
      debugPrint('launch error: $e');
    } catch (e) {
      debugPrint('launch error: $e');
    }

    // 3) 폴백: 스낵바 + 복사
    if (showSnackBarOnFail) {
      _showFailSnackBar(
        context,
        failMessage ?? '링크를 열 수 없습니다.',
        url,
        copyUrlOnFail,
      );
    }
    return false;
  }

  static void _showFailSnackBar(
    BuildContext context,
    String message,
    String url,
    bool copy,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message $url'),
        action:
            copy
                ? SnackBarAction(
                  label: '복사',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('링크를 복사했어요.')));
                  },
                )
                : null,
      ),
    );
  }
}
