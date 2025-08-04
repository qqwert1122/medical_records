import 'package:medical_records/services/database_service.dart';

class AnalysisService {
  static final AnalysisService _instance = AnalysisService._internal();
  factory AnalysisService() => _instance;
  AnalysisService._internal();

  // 히스토리ID가 같은 레코드들 중 'COMPLETE' 상태값이 있는지 여부를 리턴하는 함수
  Future<bool> hasCompleteStatus(String historyId) async {
    final db = await DatabaseService().database;
    final result = await db.query(
      'records',
      where: 'history_id = ? AND type = ? AND deleted_at IS NULL',
      whereArgs: [historyId, 'COMPLETE'],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // 스팟별 이미지들 리턴
  Future<List<Map<String, dynamic>>> getImagesBySpot(int spotId) async {
    final db = await DatabaseService().database;
    return await db.rawQuery(
      '''
      SELECT i.image_id, i.image_url, i.created_at, r.record_id, r.date, r.memo
      FROM images i
      INNER JOIN records r ON i.record_id = r.record_id
      WHERE r.spot_id = ? AND i.deleted_at IS NULL AND r.deleted_at IS NULL
      ORDER BY r.date DESC
    ''',
      [spotId],
    );
  }

  // 증상별 이미지들 리턴
  Future<List<Map<String, dynamic>>> getImagesBySymptom(int symptomId) async {
    final db = await DatabaseService().database;
    return await db.rawQuery(
      '''
      SELECT i.image_id, i.image_url, i.created_at, r.record_id, r.date, r.memo
      FROM images i
      INNER JOIN records r ON i.record_id = r.record_id
      WHERE r.symptom_id = ? AND i.deleted_at IS NULL AND r.deleted_at IS NULL
      ORDER BY r.date DESC
    ''',
      [symptomId],
    );
  }
}
