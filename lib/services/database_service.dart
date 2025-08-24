import 'package:flutter/material.dart';
import 'package:medical_records/services/file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'medical_records.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        record_id INTEGER PRIMARY KEY AUTOINCREMENT,
        status TEXT NOT NULL,
        color TEXT NOT NULL, 
        spot_id INTEGER NOT NULL,
        spot_name TEXT NOT NULL,
        symptom_id INTEGER NOT NULL,
        symptom_name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (spot_id) REFERENCES spots (spot_id)
      )
    '''); // status = ['PROGRESS', 'COMPLETE']

    await db.execute('''
      CREATE TABLE histories (
        history_id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER NOT NULL,
        event_type TEXT NOT NULL,
        treatment_id INTEGER,
        treatment_name TEXT,
        memo TEXT,
        record_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (record_id) REFERENCES records (record_id),
        FOREIGN KEY (treatment_id) REFERENCES treatments (treatment_id)
      )
    ''');

    // event_type = ['INITIAL','PROGRESS','TREATMENT','COMPLETE']

    await db.execute('''
      CREATE TABLE spots (
        spot_id INTEGER PRIMARY KEY AUTOINCREMENT,
        spot_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_used_at TEXT,
        deleted_at TEXT,
        count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE symptoms (
        symptom_id INTEGER PRIMARY KEY AUTOINCREMENT,
        symptom_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_used_at TEXT,
        deleted_at TEXT,
        count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE treatments (
        treatment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        treatment_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_used_at TEXT,
        deleted_at TEXT,
        count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE images (
        image_id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_id INTEGER,
        image_url TEXT NOT NULL,
        created_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (history_id) REFERENCES histories (history_id)
      )
    ''');

    await _createIndexes(db);
  }

  // INDEXING
  Future<void> _createIndexes(Database db) async {
    // records
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_deleted_at ON records(deleted_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_start_date ON records(start_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_end_date ON records(end_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_status ON records(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_spot_id ON records(spot_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_symptom_id ON records(symptom_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_created_at ON records(created_at)',
    );

    // histories
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_histories_record_id ON histories(record_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_histories_treatment_id ON histories(treatment_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_histories_event_type ON histories(event_type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_histories_record_date ON histories(record_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_histories_deleted_at ON histories(deleted_at)',
    );

    // spots / symptoms (정렬/조회에 쓰는 컬럼)
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_spots_deleted_at ON spots(deleted_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_spots_last_used ON spots(last_used_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_spots_count ON spots(count)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_symptoms_deleted_at ON symptoms(deleted_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_symptoms_last_used ON symptoms(last_used_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_symptoms_count ON symptoms(count)',
    );

    // treatments
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_treatments_deleted_at ON treatments(deleted_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_treatments_last_used ON treatments(last_used_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_treatments_count ON treatments(count)',
    );

    // images
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_images_history_id ON images(history_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_images_deleted_at ON images(deleted_at)',
    );
  }

  // 초기값 부여
  Future<void> ensureSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    const seedKey = 'db_seeded_v1'; // 나중에 기본값 변경 시 v2 등으로 키만 올리면 됨

    if (prefs.getBool(seedKey) == true) return;

    await createSpot(name: '입술 주변');
    await createSpot(name: '혓바닥');
    await createSpot(name: '입 천장');
    await createSpot(name: '목구멍');

    await createSymptom('입병');
    await createSymptom('염증');

    await createTreatment('가글');
    await createTreatment('약 복용');

    await prefs.setBool(seedKey, true);
  }

  // spots CRUD
  Future<int> createSpot({required String name}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('spots', {
      'spot_name': name,
      'created_at': now,
      'updated_at': now,
      'last_used_at': null,
      'deleted_at': null,
      'count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSpots() async {
    final db = await database;
    return await db.query(
      'spots',
      where: 'deleted_at IS NULL',
      orderBy: 'count DESC, last_used_at DESC',
    );
  }

  Future<void> updateSpot({required int spotId, required String name}) async {
    final db = await database;
    await db.update(
      'spots',
      {'spot_name': name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'spot_id = ?',
      whereArgs: [spotId],
    );
  }

  Future<void> updateSpotUsage(int spotId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawUpdate(
      'UPDATE spots SET last_used_at = ?, count = count + 1 WHERE spot_id = ?',
      [now, spotId],
    );
  }

  Future<void> deleteSpot(int spotId) async {
    final db = await database;
    await db.update(
      'spots',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'spot_id = ?',
      whereArgs: [spotId],
    );
  }

  // symptoms CRUD
  Future<int> createSymptom(String name) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('symptoms', {
      'symptom_name': name,
      'created_at': now,
      'updated_at': now,
      'last_used_at': null,
      'deleted_at': null,
      'count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSymptoms() async {
    final db = await database;
    return await db.query(
      'symptoms',
      where: 'deleted_at IS NULL',
      orderBy: 'count DESC, last_used_at DESC',
    );
  }

  Future<void> updateSymptom(int symptomId, String name) async {
    final db = await database;
    await db.update(
      'symptoms',
      {'symptom_name': name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'symptom_id = ?',
      whereArgs: [symptomId],
    );
  }

  Future<void> updateSymptomUsage(int symptomId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawUpdate(
      'UPDATE symptoms SET last_used_at = ?, count = count + 1 WHERE symptom_id = ?',
      [now, symptomId],
    );
  }

  Future<void> deleteSymptom(int symptomId) async {
    final db = await database;
    await db.update(
      'symptoms',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'symptom_id = ?',
      whereArgs: [symptomId],
    );
  }

  // Treatments CRUD
  Future<int> createTreatment(String name) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('treatments', {
      'treatment_name': name,
      'created_at': now,
      'updated_at': now,
      'last_used_at': null,
      'deleted_at': null,
      'count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getTreatments() async {
    final db = await database;
    return await db.query(
      'treatments',
      where: 'deleted_at IS NULL',
      orderBy: 'count DESC, last_used_at DESC',
    );
  }

  Future<void> updateTreatment({
    required int treatmentId,
    required String name,
  }) async {
    final db = await database;
    await db.update(
      'treatments',
      {'treatment_name': name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'treatment_id = ?',
      whereArgs: [treatmentId],
    );
  }

  Future<void> updateTreatmentUsage(int treatmentId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.rawUpdate(
      'UPDATE treatments SET last_used_at = ?, count = count + 1 WHERE treatment_id = ?',
      [now, treatmentId],
    );
  }

  Future<void> deleteTreatment(int treatmentId) async {
    final db = await database;
    await db.update(
      'treatments',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'treatment_id = ?',
      whereArgs: [treatmentId],
    );
  }

  // Records CRUD

  Future<int> createRecord({
    required String status, // PROGRESS, COMPLETE
    required String color,
    required int spotId,
    required String spotName,
    required int symptomId,
    required String symptomName,
    required String startDate,
    String? endDate,
    String? initialMemo,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final recordId = await db.insert('records', {
      'status': status,
      'color': color,
      'spot_id': spotId,
      'spot_name': spotName,
      'symptom_id': symptomId,
      'symptom_name': symptomName,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': now,
      'updated_at': now,
    });

    await createHistory(
      recordId: recordId,
      eventType: 'INITIAL',
      memo: initialMemo,
      recordDate: startDate,
    );

    return recordId;
  }

  Future<Map<String, dynamic>?> getRecord(int recordId) async {
    final db = await database;
    final results = await db.query(
      'records',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getRecords({
    int? spotId,
    int? symptomId,
    int? treatmentId,
  }) async {
    final db = await database;
    final whereParts = <String>['r.deleted_at IS NULL'];
    final args = <Object?>[];

    if (spotId != null) {
      whereParts.add('r.spot_id = ?');
      args.add(spotId);
    }
    if (symptomId != null) {
      whereParts.add('r.symptom_id = ?');
      args.add(symptomId);
    }

    if (treatmentId != null) {
      // histories에 해당 treatment가 1건이라도 있는 record만
      whereParts.add(
        'EXISTS (SELECT 1 FROM histories h '
        'WHERE h.record_id = r.record_id '
        'AND h.deleted_at IS NULL '
        'AND h.treatment_id = ?)',
      );
      args.add(treatmentId);
    }

    final sql = '''
      SELECT r.*
      FROM records r
      WHERE ${whereParts.join(' AND ')}
      ORDER BY r.created_at DESC, r.record_id DESC
    ''';

    return db.rawQuery(sql, args);
  }

  Future<List<Map<String, dynamic>>> getRecordsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    return await db.query(
      'records',
      where: 'deleted_at IS NULL AND start_date >= ? AND start_date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'start_date DESC',
    );
  }

  Future<int> updateRecord({
    required int recordId,
    required String status,
    required String color,
    required int spotId,
    required String spotName,
    required int symptomId,
    required String symptomName,
    required String startDate,
    String? endDate,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'records',
      {
        'status': status,
        'color': color,
        'spot_id': spotId,
        'spot_name': spotName,
        'symptom_id': symptomId,
        'symptom_name': symptomName,
        'updated_at': now,
        'start_date': startDate,
        'end_date': endDate,
      },
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  Future<int> endRecord({required int recordId, String? endDate}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      'records',
      {'status': 'COMPLETE', 'updated_at': now, 'end_date': endDate ?? now},
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  // histories CRUD
  Future<int> createHistory({
    required int recordId,
    required String eventType, // INITIAL, PROGRESS, TREATMENT, COMPLETE
    int? treatmentId,
    String? treatmentName,
    String? memo,
    required String recordDate,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('histories', {
      'record_id': recordId,
      'event_type': eventType,
      'treatment_id': treatmentId,
      'treatment_name': treatmentName,
      'memo': memo,
      'record_date': recordDate,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  Future<List<Map<String, dynamic>>> getHistories(int recordId) async {
    final db = await database;
    return await db.query(
      'histories',
      where: 'record_id = ? AND deleted_at IS NULL',
      whereArgs: [recordId],
      orderBy: 'record_date DESC, history_id DESC',
    );
  }

  Future<int> updateHistory({
    required int historyId,
    required String eventType,
    int? treatmentId,
    String? treatmentName,
    String? memo,
    required String recordDate,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final updateData = <String, dynamic>{
      'event_type': eventType,
      'record_date': recordDate,
      'updated_at': now,
    };

    if (treatmentId != null) updateData['treatment_id'] = treatmentId;
    if (treatmentName != null) updateData['treatment_name'] = treatmentName;
    if (memo != null) updateData['memo'] = memo;

    return await db.update(
      'histories',
      updateData,
      where: 'history_id = ?',
      whereArgs: [historyId],
    );
  }

  Future<void> deleteHistory(int historyId) async {
    final db = await database;
    await db.update(
      'histories',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'history_id = ?',
      whereArgs: [historyId],
    );
  }

  // Image CRUD
  Future<void> saveImages(int historyId, List<String> imagePaths) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    for (String path in imagePaths) {
      await db.insert('images', {
        'history_id': historyId,
        'image_url': path,
        'created_at': now,
        'deleted_at': null,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getImages(int historyId) async {
    final db = await database;
    return await db.query(
      'images',
      where: 'history_id = ? AND deleted_at IS NULL',
      whereArgs: [historyId],
    );
  }

  Future<Map<String, dynamic>?> getImageById(int imageId) async {
    final db = await database;
    final result = await db.query(
      'images',
      where: 'image_id = ? AND deleted_at IS NULL',
      whereArgs: [imageId],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteImage(int imageId) async {
    final image = await getImageById(imageId);
    if (image != null) {
      await FileService().deleteImage(image['image_url']);
    }

    // DB에서 완전 삭제
    final db = await database;
    await db.delete('images', where: 'image_id = ?', whereArgs: [imageId]);
  }

  Future<void> deleteAllImagesByHistoryId(int historyId) async {
    final db = await database;
    await db.delete('images', where: 'history_id = ?', whereArgs: [historyId]);
  }
}
