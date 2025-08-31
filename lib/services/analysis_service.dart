import 'package:medical_records/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class AnalysisService {
  static final AnalysisService _instance = AnalysisService._internal();
  factory AnalysisService() => _instance;
  AnalysisService._internal();

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

  Future<List<Map<String, dynamic>>> getSpotsLastUsedAt() async {
    final db = await DatabaseService().database;
    return db.rawQuery('''
        SELECT spot_id, MAX(start_date) AS last_used_at
        FROM records
        WHERE deleted_at IS NULL
        GROUP BY spot_id
      ''');
  }

  Future<List<Map<String, dynamic>>> getSymptomsLastUsedAt() async {
    final db = await DatabaseService().database;
    return db.rawQuery('''
        SELECT symptom_id, MAX(start_date) AS last_used_at
        FROM records
        WHERE deleted_at IS NULL
        GROUP BY symptom_id
      ''');
  }

  Future<List<Map<String, dynamic>>> getTreatmentsLastUsedAt() async {
    final db = await DatabaseService().database;
    return db.rawQuery('''
        SELECT treatment_id, MAX(record_date) AS last_used_at
        FROM histories
        WHERE deleted_at IS NULL
          AND event_type = 'TREATMENT'
          AND treatment_id IS NOT NULL
        GROUP BY treatment_id
      ''');
  }
}
