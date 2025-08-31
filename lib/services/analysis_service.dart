import 'package:medical_records/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class AnalysisService {
  static final AnalysisService _instance = AnalysisService._internal();
  factory AnalysisService() => _instance;
  AnalysisService._internal();

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

  // 상관계수
  Future<List<Map<String, dynamic>>> getSymptomSpotCooc() async {
    final db = await DatabaseService().database;
    return db.rawQuery('''
      SELECT r.symptom_id, r.symptom_name, r.spot_id, r.spot_name, COUNT(*) AS cnt
      FROM records r
      WHERE r.deleted_at IS NULL
      GROUP BY r.symptom_id, r.spot_id
    ''');
  }

  Future<
    ({
      Map<(int, int), int> cooc,
      Map<int, int> symTotals,
      Map<int, int> spotTotals,
      int N,
    })
  >
  buildSymptomSpotCounts() async {
    final rows = await getSymptomSpotCooc();

    final cooc = <(int, int), int>{};
    final symTotals = <int, int>{};
    final spotTotals = <int, int>{};
    var N = 0;

    for (final r in rows) {
      final sid = r['symptom_id'] as int;
      final pid = r['spot_id'] as int;
      final cnt = (r['cnt'] as int);

      cooc[(sid, pid)] = cnt;
      symTotals[sid] = (symTotals[sid] ?? 0) + cnt;
      spotTotals[pid] = (spotTotals[pid] ?? 0) + cnt;
      N += cnt;
    }

    return (cooc: cooc, symTotals: symTotals, spotTotals: spotTotals, N: N);
  }

  Future<List<Map<String, dynamic>>> getSymptomsForPicker() =>
      DatabaseService().getSymptoms();
  Future<List<Map<String, dynamic>>> getSpotsForPicker() =>
      DatabaseService().getSpots();
}
