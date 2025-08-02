import 'package:flutter/material.dart';
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
        memo TEXT,
        histories_id INTEGER,
        spot_id INTEGER NOT NULL,
       spot_name TEXT NOT NULL,
        spot_color TEXT NOT NULL, 
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (histories_id) REFERENCES histories (histories_id),
        FOREIGN KEY (spot_id) REFERENCES categories (spot_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE spots (
        spot_id INTEGER PRIMARY KEY AUTOINCREMENT,
        spot_name TEXT NOT NULL,
        spot_color TEXT NOT NULL,
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
      CREATE TABLE histories (
        histories_id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_id TEXT NOT NULL,
        memo TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
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
      'spot_color': Colors.red.shade400.toARGB32().toString(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('spots', {
      'spot_name': '혓바닥',
      'spot_color': Colors.orange.shade400.toARGB32().toString(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('spots', {
      'spot_name': '입 천장',
      'spot_color': Colors.blue.shade400.toARGB32().toString(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('spots', {
      'spot_name': '목구멍',
      'spot_color': Colors.indigo.shade400.toARGB32().toString(),
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
      'spot_color': color,
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
      {
        'spot_name': name,
        'spot_color': color,
        'updated_at': DateTime.now().toIso8601String(),
      },
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
    required String memo,
    required int spotId,
    required String spotName,
    required String spotColor,
    int? historiesId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('records', {
      'memo': memo,
      'spot_id': spotId,
      'spot_name': spotName,
      'spot_color': spotColor,
      'histories_id': historiesId,
      'created_at': now,
      'updated_at': now,
    });
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
}
