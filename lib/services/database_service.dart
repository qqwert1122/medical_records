import 'package:flutter/material.dart';
import 'package:medical_records/services/file_service.dart';
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
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        record_id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        history_id INTEGER NOT NULL,
        memo TEXT,
        color TEXT NOT NULL, 
        spot_id INTEGER NOT NULL,
        spot_name TEXT NOT NULL,
        symptom_id INTEGER NOT NULL,
        symptom_name TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (spot_id) REFERENCES spots (spot_id)
      )
    ''');

    // type = ['INITIAL','PROGRESS','TREATMENT','COMPLETE']

    await db.execute('''
      CREATE TABLE spots (
        spot_id INTEGER PRIMARY KEY AUTOINCREMENT,
        spot_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_used_at TEXT,
        deleted_at TEXT,
        count INTEGER
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
        count INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE images (
        image_id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER,
        image_url TEXT NOT NULL,
        created_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (record_id) REFERENCES records (record_id)
      )
    ''');

    await db.insert('spots', {
      'spot_name': '입술 주변',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('spots', {
      'spot_name': '혓바닥',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('spots', {
      'spot_name': '입 천장',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('spots', {
      'spot_name': '목구멍',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('symptoms', {
      'symptom_name': '입병',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('symptoms', {
      'symptom_name': '염증',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });
  }

  // spots CRUD
  Future<List<Map<String, dynamic>>> getSpots() async {
    final db = await database;
    return await db.query(
      'spots',
      where: 'deleted_at IS NULL',
      orderBy: 'count, last_used_at DESC',
    );
  }

  Future<int> createSpot(String name, String color) async {
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

  Future<void> updateSpot(int spotId, String name, String color) async {
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
    await db.update(
      'spots',
      {
        'last_used_at': DateTime.now().toIso8601String(),
        'count': '(count + 1)',
      },
      where: 'spot_id = ?',
      whereArgs: [spotId],
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
  Future<List<Map<String, dynamic>>> getSymptoms() async {
    final db = await database;
    return await db.query(
      'symptoms',
      where: 'deleted_at IS NULL',
      orderBy: 'count, last_used_at DESC',
    );
  }

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

  Future<void> updateSymptom(int symptomId, String name) async {
    final db = await database;
    await db.update(
      'spots',
      {'symptom_name': name, 'updated_at': DateTime.now().toIso8601String()},
      where: 'symptom_id = ?',
      whereArgs: [symptomId],
    );
  }

  Future<void> updateSymptomUsage(int symptomId) async {
    final db = await database;
    await db.update(
      'spots',
      {
        'last_used_at': DateTime.now().toIso8601String(),
        'count': '(count + 1)',
      },
      where: 'symptom_id = ?',
      whereArgs: [symptomId],
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

  // Records CRUD
  Future<List<Map<String, dynamic>>> getRecords({int? spotId}) async {
    final db = await database;
    String where = 'deleted_at IS NULL';
    List<dynamic> whereArgs = [];

    if (spotId != null) {
      where += ' AND spot_id = ?';
      whereArgs.add(spotId);
    }

    return await db.query(
      'records',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
  }

  Future<int> createRecord({
    required String type,
    required String historyId,
    required String memo,
    required String color,
    required int spotId,
    required String spotName,
    required int symptomId,
    required String symptomName,
    required String date,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('records', {
      'type': type,
      'history_id': historyId,
      'memo': memo,
      'color': color,
      'spot_id': spotId,
      'spot_name': spotName,
      'symptom_id': symptomId,
      'symptom_name': symptomName,
      'created_at': now,
      'updated_at': now,
      'date': date,
    });
  }

  Future<int> updateRecord({
    required int recordId,
    required String type,
    required String historyId,
    required String memo,
    required String color,
    required int spotId,
    required String spotName,
    required int symptomId,
    required String symptomName,
    required String date,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'records',
      {
        'type': type,
        'history_id': historyId,
        'memo': memo,
        'color': color,
        'spot_id': spotId,
        'spot_name': spotName,
        'symptom_id': symptomId,
        'symptom_name': symptomName,
        'updated_at': now,
        'date': date,
      },
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  // Image CRUD
  Future<void> saveImages(int recordId, List<String> imagePaths) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    for (String path in imagePaths) {
      await db.insert('images', {
        'record_id': recordId,
        'image_url': path,
        'created_at': now,
        'deleted_at': null,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getImages(int recordId) async {
    final db = await database;
    return await db.query(
      'images',
      where: 'record_id = ? AND deleted_at IS NULL',
      whereArgs: [recordId],
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
    // 파일도 완전 삭제
    print('imageId: $imageId');
    final image = await getImageById(imageId);
    if (image != null) {
      await FileService().deleteImage(image['image_url']);
    }

    // DB에서 완전 삭제
    final db = await database;
    await db.delete('images', where: 'image_id = ?', whereArgs: [imageId]);
  }

  Future<void> deleteAllImagesByRecordId(int recordId) async {
    final db = await database;
    await db.delete('images', where: 'record_id = ?', whereArgs: [recordId]);
  }
}
