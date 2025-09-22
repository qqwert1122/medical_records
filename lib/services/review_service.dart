import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:medical_records/config/store_secret.dart';
import 'package:medical_records/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqlite_api.dart';

class ReviewService {
  static const String _hasRequestedReviewKey = 'has_requested_review';
  static final InAppReview _inAppReview = InAppReview.instance;

  // 리뷰를 이미 요청했는지 확인
  static Future<bool> hasRequestedReview() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasRequestedReviewKey) ?? false;
  }

  // 리뷰 요청 상태를 저장
  static Future<void> setReviewRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRequestedReviewKey, true);
  }

  // 특정 조건을 충족했을 때 최초 1회만 리뷰 요청
  static Future<void> requestReviewIfEligible(BuildContext context) async {
    try {
      // 이미 요청했다면 종료
      if (await hasRequestedReview()) {
        print('이미 리뷰를 요청했습니다.');
        return;
      }

      bool shouldRequestReview = await _checkReviewConditions(context);

      if (shouldRequestReview) {
        print('리뷰 조건을 충족했습니다. 리뷰를 요청합니다.');

        bool success = await requestReview();
        if (success) {
          await setReviewRequested();
          print('리뷰 요청이 완료되었습니다.');
        }
      } else {
        print('리뷰 조건을 충족하지 않았습니다.');
      }
    } catch (e) {
      print('리뷰 조건 체크 중 오류 발생: $e');
    }
  }

  // 리뷰 요청 조건 체크 함수
  static Future<bool> _checkReviewConditions(BuildContext context) async {
    try {
      final recordCount = await DatabaseService().getRecordsCount();
      print('현재 기록된 진료 기록 수: $recordCount');
      // 조건: 진료 기록이 5개 이상일 때
      if (recordCount >= 5) {
        print('리뷰 요청 조건을 충족했습니다.');
        return true;
      }

      return false;
    } catch (e) {
      print('조건 체크 중 오류: $e');
      return false;
    }
  }

  // 리뷰 요청 (앱 내에서 바로) - 설정에서 직접 호출용
  static Future<bool> requestReview() async {
    try {
      print('리뷰 요청 시도 중...');

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        print('인앱 리뷰 요청 성공');
        return true;
      } else {
        print('인앱 리뷰를 사용할 수 없어 스토어로 이동합니다.');
        await openStoreListing();
        return false;
      }
    } catch (e) {
      print('리뷰 요청 중 오류 발생: $e');
      // 오류 발생 시에도 스토어로 이동 시도
      await openStoreListing();
      return false;
    }
  }

  // 앱스토어로 이동 (fallback 용도)
  static Future<void> openStoreListing() async {
    try {
      print('앱스토어로 이동 중...');
      await _inAppReview.openStoreListing(
        appStoreId: StoreSecrets.iosAppStoreId,
      );
      print('앱스토어 이동 성공');
    } catch (e) {
      print('스토어 열기 중 오류 발생: $e');
    }
  }

  /// 디버깅용 - 현재 상태 확인
  static Future<void> debugReviewStatus(BuildContext context) async {
    try {
      final records = await DatabaseService().getRecords();
      final recordCount = records.length;
      bool result = false;

      print('현재 기록된 진료 기록 수: $recordCount');
      // 조건: 진료 기록이 5개 이상일 때
      if (recordCount >= 5) {
        print('리뷰 요청 조건을 충족했습니다.');
        result = true;
      }

      print('result: $result');
    } catch (e) {
      print('디버깅 중 오류: $e');
    }
  }

  // 테스트용 - 리뷰 요청 상태 초기화
  static Future<void> resetReviewStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasRequestedReviewKey);
      print('리뷰 요청 상태가 초기화되었습니다.');
    } catch (e) {
      print('초기화 중 오류: $e');
    }
  }
}
