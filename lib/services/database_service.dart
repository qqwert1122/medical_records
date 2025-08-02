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
        category_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        category_color TEXT NOT NULL, 
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (histories_id) REFERENCES histories (histories_id),
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_name TEXT NOT NULL,
        category_color TEXT NOT NULL,
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

    await db.insert('categories', {
      'category_name': '입술 주변',
      'category_color': Colors.red.shade400.toARGB32().toString(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('categories', {
      'category_name': '혓바닥',
      'category_color': Colors.orange.shade400.toARGB32().toString(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('categories', {
      'category_name': '입 천장',
      'category_color': Colors.blue.shade400.toARGB32().toString(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });

    await db.insert('categories', {
      'category_name': '목구멍',
      'category_color': Colors.indigo.shade400.toARGB32().toString(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'count': 0,
    });
  }

  // Categories CRUD
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'count, last_used_at DESC',
    );
  }

  Future<int> createCategory(String name, String color) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert('categories', {
      'category_name': name,
      'category_color': color,
      'created_at': now,
      'updated_at': now,
      'last_used_at': null,
      'deleted_at': null,
      'count': 0,
    });
  }

  Future<void> updateCategory(int categoryId, String name, String color) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'category_name': name,
        'category_color': color,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<void> updateCategoryUsage(int categoryId) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'last_used_at': DateTime.now().toIso8601String(),
        'count': '(count + 1)',
      },
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    await db.update(
      'categories',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // Records CRUD
  Future<List<Map<String, dynamic>>> getRecords({int? categoryId}) async {
    final db = await database;
    String where = 'deleted_at IS NULL';
    List<dynamic> whereArgs = [];

    if (categoryId != null) {
      where += ' AND category_id = ?';
      whereArgs.add(categoryId);
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
    required int categoryId,
    required String categoryName,
    required String categoryColor,
    int? historiesId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('records', {
      'memo': memo,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_color': categoryColor,
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
