import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class SharedPreferencesService {
  static Database? _cachedDb;
  static const _tableName = 'app_kv_store';

  Future<Database> get _db async {
    final cached = _cachedDb;
    if (cached != null) return cached;

    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'our_recipe.db');
    _cachedDb = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _cachedDb!;
  }

  Future<String?> getString(String key) async {
    final rows = await (await _db).query(
      _tableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final value = rows.first['value'];
    return value is String ? value : null;
  }

  Future<bool> setString(String key, String value) async {
    await (await _db).insert(_tableName, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }

  Future<bool> remove(String key) async {
    await (await _db).delete(
      _tableName,
      where: 'key = ?',
      whereArgs: [key],
    );
    return true;
  }

  Future<T?> getJson<T>(
    String key,
    T Function(Object? decoded) decoder,
  ) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return decoder(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<bool> setJson(String key, Object value) async {
    return setString(key, jsonEncode(value));
  }
}
