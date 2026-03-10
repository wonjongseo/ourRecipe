import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:our_recipe/core/services/app_data_path_service.dart';
import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';

/// 충돌 처리 방식.
enum ICloudConflictStrategy { merge, overwrite }

/// iCloud 사용 불가(Drive OFF, 앱 토글 OFF 등) 상태 예외.
class ICloudUnavailableException implements Exception {}

/// ON/OFF 토글 시 DB + 이미지를 경로 간 복사/정리해주는 서비스.
class ICloudSyncMigrationService {
  static const String _dbFileName = 'our_recipe_data.db';
  static const String _recipeDeleteEventsFileName = 'recipe_delete_events.json';
  static const String _ingredientDeleteEventsFileName =
      'ingredient_delete_events.json';
  static const Set<String> _imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.heic',
    '.webp',
  };

  /// 현재 전환 방향에서 충돌(대상 DB에 이미 데이터가 있음) 여부를 판단한다.
  Future<bool> hasConflict({required bool enableICloud}) async {
    final sourceDir = await _resolveSourceDir(enableICloud: enableICloud);
    final targetDir = await _resolveTargetDir(enableICloud: enableICloud);
    final sourceDb = File(path.join(sourceDir.path, _dbFileName));
    final targetDb = File(path.join(targetDir.path, _dbFileName));
    if (!await sourceDb.exists() || !await targetDb.exists()) return false;
    return _hasAnyData(targetDb.path);
  }

  /// 로컬 <-> iCloud 양방향 병합 동기화를 수행한다.
  /// - 1차: iCloud -> local merge (pull)
  /// - 2차: local -> iCloud merge (push)
  /// - 3차: iCloud -> local merge (pull)
  ///
  /// 왜 pull -> push -> pull 인가?
  /// - 로컬만 먼저 밀어버리면, iCloud 쪽에 먼저 있던 다른 기기 데이터가 사라질 수 있다.
  /// - 먼저 pull 해서 로컬이 iCloud 내용을 포함하도록 만든 뒤 push 해야
  ///   "내 데이터 + 상대 데이터"를 같이 갖고 올라갈 수 있다.
  /// - 마지막 pull 은 push 결과를 다시 현재 기기 로컬에도 맞추기 위한 정리 단계다.
  Future<void> syncBidirectionalMerge() async {
    await migrateForToggle(
      enableICloud: false,
      strategy: ICloudConflictStrategy.merge,
    );
    await migrateForToggle(
      enableICloud: true,
      strategy: ICloudConflictStrategy.merge,
    );
    await migrateForToggle(
      enableICloud: false,
      strategy: ICloudConflictStrategy.merge,
    );
  }

  /// iCloud 데이터를 로컬로 병합 반영한다.
  Future<void> syncFromICloudToLocalMerge() async {
    await migrateForToggle(
      enableICloud: false,
      strategy: ICloudConflictStrategy.merge,
    );
  }

  /// 토글 전환 시 실제 데이터 이동을 수행한다.
  /// - source -> target 복사/병합
  /// - 정책:
  ///   - ON 전환(local -> iCloud): 복사만 수행(로컬 유지)
  ///   - OFF 전환(iCloud -> local): 복사만 수행(iCloud 유지)
  Future<void> migrateForToggle({
    required bool enableICloud,
    required ICloudConflictStrategy strategy,
  }) async {
    final sourceDir = await _resolveSourceDir(enableICloud: enableICloud);
    final targetDir = await _resolveTargetDir(enableICloud: enableICloud);
    await targetDir.create(recursive: true);

    final sourceDbPath = path.join(sourceDir.path, _dbFileName);
    final targetDbPath = path.join(targetDir.path, _dbFileName);
    final sourceDbFile = File(sourceDbPath);
    if (!await sourceDbFile.exists()) {
      // 옮길 DB가 없으면(초기 상태) 작업 종료.
      return;
    }

    // WAL/SHM은 SQLite가 쓰기 성능을 위해 같이 쓰는 보조 파일이다.
    // 문제는 iCloud가 "DB 본파일 + WAL/SHM" 조합을 기기마다 완벽히 같은 타이밍으로
    // 맞춰주지 못할 수 있다는 점이다.
    //
    // 그래서 병합 전후에 WAL 변경분을 메인 DB 파일로 밀어 넣는다.
    // 그래야 다른 기기가 "DB 본파일 하나만 봐도" 최신 내용에 가깝게 읽을 수 있다.
    await _flushDatabaseForFileSync(sourceDbPath);
    await _flushDatabaseForFileSync(targetDbPath);

    final sourceImagePaths = await _collectImagePathsFromDb(
      dbPath: sourceDbPath,
      sourceDirPath: sourceDir.path,
    );

    if (strategy == ICloudConflictStrategy.overwrite) {
      await _overwriteDatabase(
        sourceDbPath: sourceDbPath,
        targetDbPath: targetDbPath,
      );
    } else {
      await _mergeDatabase(
        sourceDbPath: sourceDbPath,
        targetDbPath: targetDbPath,
      );
    }

    await _copyImagesToTarget(
      sourceImagePaths: sourceImagePaths,
      targetDirPath: targetDir.path,
    );

    await _flushDatabaseForFileSync(targetDbPath);

    // 단순 merge만으로는 "삭제"가 전달되지 않는다.
    // 예: source에는 row가 없고 target에는 row가 있으면, merge 결과는 target row가 그대로 남는다.
    //
    // 그래서 삭제는 별도 이벤트 파일로 관리하고, pull 시 로컬에 적용한다.
    if (!enableICloud) {
      await _applyRecipeDeleteEventsToLocal(
        iCloudDirPath: sourceDir.path,
        localDbPath: targetDbPath,
      );
      await _applyIngredientDeleteEventsToLocal(
        iCloudDirPath: sourceDir.path,
        localDbPath: targetDbPath,
      );
    }
  }

  /// iCloud 컨테이너에 저장된 앱 데이터를 모두 삭제한다.
  /// - 레시피 DB 파일(본체/WAL/SHM)
  /// - 컨테이너 루트에 저장된 이미지 파일
  Future<void> deleteAllICloudData() async {
    final iCloudDirPath = await AppDataPathService.getICloudDirectoryPathIfAvailable();
    if (iCloudDirPath == null || iCloudDirPath.isEmpty) {
      throw ICloudUnavailableException();
    }

    await _deleteAllDataInDirectory(iCloudDirPath);
  }

  /// iCloud DB/이미지에서 특정 레시피를 삭제한다.
  Future<void> deleteRecipeFromICloud(String recipeId) async {
    final iCloudDirPath = await AppDataPathService.getICloudDirectoryPathIfAvailable();
    if (iCloudDirPath == null || iCloudDirPath.isEmpty) {
      throw ICloudUnavailableException();
    }
    final dbPath = path.join(iCloudDirPath, _dbFileName);
    if (!await File(dbPath).exists()) return;

    final db = await openDatabase(dbPath);
    try {
      final imagePaths = <String>{};

      final coverRows = await db.query(
        RecipeDatabaseService.recipes,
        columns: ['cover_image_path'],
        where: 'id = ?',
        whereArgs: [recipeId],
        limit: 1,
      );
      if (coverRows.isNotEmpty) {
        final raw = (coverRows.first['cover_image_path'] as String?)?.trim();
        final resolved = _resolveImagePath(raw, iCloudDirPath);
        if (resolved != null && path.isWithin(iCloudDirPath, resolved)) {
          imagePaths.add(resolved);
        }
      }

      final stepRows = await db.query(
        RecipeDatabaseService.recipeSteps,
        columns: ['image_path'],
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
      );
      for (final row in stepRows) {
        final raw = (row['image_path'] as String?)?.trim();
        final resolved = _resolveImagePath(raw, iCloudDirPath);
        if (resolved != null && path.isWithin(iCloudDirPath, resolved)) {
          imagePaths.add(resolved);
        }
      }

      await db.transaction((txn) async {
        await txn.delete(
          RecipeDatabaseService.recipeIngredients,
          where: 'recipe_id = ?',
          whereArgs: [recipeId],
        );
        await txn.delete(
          RecipeDatabaseService.recipeSteps,
          where: 'recipe_id = ?',
          whereArgs: [recipeId],
        );
        await txn.delete(
          RecipeDatabaseService.recipes,
          where: 'id = ?',
          whereArgs: [recipeId],
        );
      });

      await _appendRecipeDeleteEvent(
        iCloudDirPath: iCloudDirPath,
        recipeId: recipeId,
      );

      for (final imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } finally {
      await db.close();
    }
  }

  /// iCloud DB에서 사용자 등록 재료를 삭제한다.
  Future<void> deleteIngredientProductFromICloud(String productId) async {
    final iCloudDirPath =
        await AppDataPathService.getICloudDirectoryPathIfAvailable();
    if (iCloudDirPath == null || iCloudDirPath.isEmpty) {
      throw ICloudUnavailableException();
    }
    final dbPath = path.join(iCloudDirPath, _dbFileName);
    if (!await File(dbPath).exists()) return;

    final db = await openDatabase(dbPath);
    try {
      await db.delete(
        RecipeDatabaseService.ingredientProducts,
        where: 'id = ? AND is_default = 0',
        whereArgs: [productId],
      );
      await _appendIngredientDeleteEvent(
        iCloudDirPath: iCloudDirPath,
        productId: productId,
      );
    } finally {
      await db.close();
    }
  }

  /// iCloud DB에 사용자 등록 재료를 저장/수정한다.
  Future<void> upsertIngredientProductToICloud(
    IngredientProductModel product,
  ) async {
    final iCloudDirPath =
        await AppDataPathService.getICloudDirectoryPathIfAvailable();
    if (iCloudDirPath == null || iCloudDirPath.isEmpty) {
      throw ICloudUnavailableException();
    }

    final dbPath = path.join(iCloudDirPath, _dbFileName);
    await Directory(iCloudDirPath).create(recursive: true);

    final db = await openDatabase(dbPath, version: 1);
    try {
      await db.insert(RecipeDatabaseService.ingredientProducts, {
        'id': product.id,
        'name': product.name,
        'category': product.category,
        'manufacturer': product.manufacturer,
        'price': product.price,
        'base_gram': product.baseGram,
        'kcal': product.kcal,
        'water': product.water,
        'protein': product.protein,
        'fat': product.fat,
        'carbohydrate': product.carbohydrate,
        'fiber': product.fiber,
        'ash': product.ash,
        'sodium': product.sodium,
        'is_default': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } finally {
      await db.close();
    }
  }

  /// 로컬 Documents에 저장된 앱 데이터를 모두 삭제한다.
  Future<void> deleteAllLocalData() async {
    final localDirPath = await AppDataPathService.getLocalDocumentsPath();
    await _deleteAllDataInDirectory(localDirPath);
  }

  Future<Directory> _resolveSourceDir({required bool enableICloud}) async {
    if (enableICloud) {
      return Directory(await AppDataPathService.getLocalDocumentsPath());
    }
    final iCloud = await AppDataPathService.getICloudDirectoryPathIfAvailable();
    if (iCloud == null || iCloud.isEmpty) throw ICloudUnavailableException();
    return Directory(iCloud);
  }

  Future<Directory> _resolveTargetDir({required bool enableICloud}) async {
    if (!enableICloud) {
      return Directory(await AppDataPathService.getLocalDocumentsPath());
    }
    final iCloud = await AppDataPathService.getICloudDirectoryPathIfAvailable();
    if (iCloud == null || iCloud.isEmpty) throw ICloudUnavailableException();
    return Directory(iCloud);
  }

  Future<bool> _hasAnyData(String dbPath) async {
    final db = await openDatabase(dbPath, readOnly: true);
    try {
      for (final table in _tables) {
        final result = await db.rawQuery(
          'SELECT EXISTS(SELECT 1 FROM $table LIMIT 1) AS e',
        );
        final exists = (result.first['e'] as int? ?? 0) == 1;
        if (exists) return true;
      }
      return false;
    } finally {
      await db.close();
    }
  }

  Future<void> _overwriteDatabase({
    required String sourceDbPath,
    required String targetDbPath,
  }) async {
    final targetDb = File(targetDbPath);
    if (await targetDb.exists()) {
      await targetDb.delete();
    }
    await File(sourceDbPath).copy(targetDbPath);
    await _copyIfExists('$sourceDbPath-wal', '$targetDbPath-wal');
    await _copyIfExists('$sourceDbPath-shm', '$targetDbPath-shm');
  }

  Future<void> _mergeDatabase({
    required String sourceDbPath,
    required String targetDbPath,
  }) async {
    final targetDb = File(targetDbPath);
    if (!await targetDb.exists()) {
      await _overwriteDatabase(
        sourceDbPath: sourceDbPath,
        targetDbPath: targetDbPath,
      );
      return;
    }

    final source = await openDatabase(sourceDbPath, readOnly: true);
    final target = await openDatabase(targetDbPath);
    try {
      await target.transaction((txn) async {
        // recipes는 updated_at이 더 최신인 row만 반영한다.
        final replacedRecipeIds = <String>{};
        final sourceRecipes = await source.query(RecipeDatabaseService.recipes);
        for (final row in sourceRecipes) {
          final recipeId = row['id'] as String?;
          if (recipeId == null || recipeId.isEmpty) continue;

          final targetRows = await txn.query(
            RecipeDatabaseService.recipes,
            columns: ['updated_at'],
            where: 'id = ?',
            whereArgs: [recipeId],
            limit: 1,
          );

          final shouldReplace =
              targetRows.isEmpty ||
              _isSourceRecipeNewer(
                sourceUpdatedAt: row['updated_at'],
                targetUpdatedAt:
                    targetRows.isEmpty ? null : targetRows.first['updated_at'],
              );
          if (!shouldReplace) continue;

          await txn.insert(
            RecipeDatabaseService.recipes,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          replacedRecipeIds.add(recipeId);
        }

        // 최신 레시피가 source로 채택된 경우 해당 하위 테이블도 source 기준으로 교체한다.
        for (final recipeId in replacedRecipeIds) {
          await txn.delete(
            RecipeDatabaseService.recipeIngredients,
            where: 'recipe_id = ?',
            whereArgs: [recipeId],
          );
          await txn.delete(
            RecipeDatabaseService.recipeSteps,
            where: 'recipe_id = ?',
            whereArgs: [recipeId],
          );

          final sourceIngredients = await source.query(
            RecipeDatabaseService.recipeIngredients,
            where: 'recipe_id = ?',
            whereArgs: [recipeId],
          );
          for (final row in sourceIngredients) {
            await txn.insert(
              RecipeDatabaseService.recipeIngredients,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          final sourceSteps = await source.query(
            RecipeDatabaseService.recipeSteps,
            where: 'recipe_id = ?',
            whereArgs: [recipeId],
          );
          for (final row in sourceSteps) {
            await txn.insert(
              RecipeDatabaseService.recipeSteps,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }

        // 나머지 테이블은 기존처럼 source 값을 반영한다.
        for (final table in _tables) {
          if (table == RecipeDatabaseService.recipes) continue;
          if (table == RecipeDatabaseService.recipeIngredients) continue;
          if (table == RecipeDatabaseService.recipeSteps) continue;
          final rows = await source.query(table);
          for (final row in rows) {
            await txn.insert(
              table,
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
    } finally {
      await source.close();
      await target.close();
    }
  }

  bool _isSourceRecipeNewer({
    required Object? sourceUpdatedAt,
    required Object? targetUpdatedAt,
  }) {
    final source = _parseDateTime(sourceUpdatedAt);
    final target = _parseDateTime(targetUpdatedAt);
    if (source == null) return false;
    if (target == null) return true;
    return source.isAfter(target);
  }

  DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  Future<Set<String>> _collectImagePathsFromDb({
    required String dbPath,
    required String sourceDirPath,
  }) async {
    final db = await openDatabase(dbPath, readOnly: true);
    final results = <String>{};
    try {
      final recipeRows = await db.query(
        RecipeDatabaseService.recipes,
        columns: ['cover_image_path'],
      );
      for (final row in recipeRows) {
        final raw = (row['cover_image_path'] as String?)?.trim();
        final resolved = _resolveImagePath(raw, sourceDirPath);
        if (resolved != null) results.add(resolved);
      }

      final stepRows = await db.query(
        RecipeDatabaseService.recipeSteps,
        columns: ['image_path'],
      );
      for (final row in stepRows) {
        final raw = (row['image_path'] as String?)?.trim();
        final resolved = _resolveImagePath(raw, sourceDirPath);
        if (resolved != null) results.add(resolved);
      }

      final logRows = await db.query(
        RecipeDatabaseService.cookLogs,
        columns: ['result_image_path'],
      );
      for (final row in logRows) {
        final raw = (row['result_image_path'] as String?)?.trim();
        final resolved = _resolveImagePath(raw, sourceDirPath);
        if (resolved != null) results.add(resolved);
      }
    } finally {
      await db.close();
    }
    return results;
  }

  String? _resolveImagePath(String? value, String sourceDirPath) {
    if (value == null || value.isEmpty) return null;
    if (path.isAbsolute(value)) {
      // 과거 경로(예: 이전 iCloud 절대경로)가 DB에 남아 있을 수 있다.
      // 해당 파일이 없으면 basename 기준으로 현재 source 폴더에서 다시 찾는다.
      final absolute = File(value);
      if (absolute.existsSync()) return value;
      return path.join(sourceDirPath, path.basename(value));
    }
    return path.join(sourceDirPath, value);
  }

  Future<void> _copyImagesToTarget({
    required Set<String> sourceImagePaths,
    required String targetDirPath,
  }) async {
    for (final sourcePath in sourceImagePaths) {
      final source = File(sourcePath);
      if (!await source.exists()) continue;
      final ext = path.extension(sourcePath).toLowerCase();
      if (!_imageExtensions.contains(ext)) continue;
      final targetPath = path.join(targetDirPath, path.basename(sourcePath));
      final target = File(targetPath);
      if (await target.exists()) continue;
      await source.copy(targetPath);
    }
  }

  Future<void> _copyIfExists(String sourcePath, String targetPath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return;
    await source.copy(targetPath);
  }

  Future<void> _flushDatabaseForFileSync(String dbPath) async {
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) return;

    Database? db;
    try {
      db = await openDatabase(dbPath);
      try {
        // WAL에 쌓인 변경을 메인 DB 파일에 강제로 반영한다.
        await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (_) {}
    } catch (_) {
      // 동기화 보강용 보조 처리이므로 실패해도 본 흐름은 유지한다.
    } finally {
      await db?.close();
    }

    await _deleteIfExists('$dbPath-wal');
    await _deleteIfExists('$dbPath-shm');
    await _deleteIfExists('$dbPath-journal');
  }

  Future<void> _deleteIfExists(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    await file.delete();
  }

  Future<void> _deleteAllDataInDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;

    // SQLite 관련 파일(db, wal, shm, journal 등)을 prefix 기준으로 전부 삭제한다.
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final baseName = path.basename(entity.path);
      if (baseName == _dbFileName || baseName.startsWith('$_dbFileName-')) {
        await entity.delete();
      }
    }

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final ext = path.extension(entity.path).toLowerCase();
      if (!_imageExtensions.contains(ext)) continue;
      await entity.delete();
    }
  }

  Future<void> _appendRecipeDeleteEvent({
    required String iCloudDirPath,
    required String recipeId,
  }) async {
    final file = File(path.join(iCloudDirPath, _recipeDeleteEventsFileName));
    List<dynamic> events = [];
    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic> && decoded['events'] is List) {
          events = List<dynamic>.from(decoded['events'] as List);
        }
      } catch (_) {}
    }

    events.add({
      'recipe_id': recipeId,
      'deleted_at': DateTime.now().toIso8601String(),
    });
    final dedup = <String, Map<String, dynamic>>{};
    for (final item in events) {
      if (item is! Map<String, dynamic>) continue;
      final id = (item['recipe_id'] as String?)?.trim();
      if (id == null || id.isEmpty) continue;
      dedup[id] = item;
    }

    await file.writeAsString(jsonEncode({'events': dedup.values.toList()}));
  }

  Future<void> _appendIngredientDeleteEvent({
    required String iCloudDirPath,
    required String productId,
  }) async {
    final file = File(path.join(iCloudDirPath, _ingredientDeleteEventsFileName));
    List<dynamic> events = [];
    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic> && decoded['events'] is List) {
          events = List<dynamic>.from(decoded['events'] as List);
        }
      } catch (_) {}
    }

    events.add({
      'product_id': productId,
      'deleted_at': DateTime.now().toIso8601String(),
    });
    final dedup = <String, Map<String, dynamic>>{};
    for (final item in events) {
      if (item is! Map<String, dynamic>) continue;
      final id = (item['product_id'] as String?)?.trim();
      if (id == null || id.isEmpty) continue;
      dedup[id] = item;
    }

    await file.writeAsString(jsonEncode({'events': dedup.values.toList()}));
  }

  Future<void> _applyRecipeDeleteEventsToLocal({
    required String iCloudDirPath,
    required String localDbPath,
  }) async {
    final eventsFile = File(path.join(iCloudDirPath, _recipeDeleteEventsFileName));
    if (!await eventsFile.exists()) return;
    final localDbFile = File(localDbPath);
    if (!await localDbFile.exists()) return;

    List<dynamic> events = [];
    try {
      final decoded = jsonDecode(await eventsFile.readAsString());
      if (decoded is Map<String, dynamic> && decoded['events'] is List) {
        events = List<dynamic>.from(decoded['events'] as List);
      }
    } catch (_) {
      return;
    }

    final recipeIds = <String>{};
    for (final item in events) {
      if (item is! Map<String, dynamic>) continue;
      final id = (item['recipe_id'] as String?)?.trim();
      if (id == null || id.isEmpty) continue;
      recipeIds.add(id);
    }
    if (recipeIds.isEmpty) return;

    final db = await openDatabase(localDbPath);
    try {
      await db.transaction((txn) async {
        for (final recipeId in recipeIds) {
          await txn.delete(
            RecipeDatabaseService.recipeIngredients,
            where: 'recipe_id = ?',
            whereArgs: [recipeId],
          );
          await txn.delete(
            RecipeDatabaseService.recipeSteps,
            where: 'recipe_id = ?',
            whereArgs: [recipeId],
          );
          await txn.delete(
            RecipeDatabaseService.recipes,
            where: 'id = ?',
            whereArgs: [recipeId],
          );
        }
      });
    } finally {
      await db.close();
    }
  }

  Future<void> _applyIngredientDeleteEventsToLocal({
    required String iCloudDirPath,
    required String localDbPath,
  }) async {
    final eventsFile = File(
      path.join(iCloudDirPath, _ingredientDeleteEventsFileName),
    );
    if (!await eventsFile.exists()) return;
    final localDbFile = File(localDbPath);
    if (!await localDbFile.exists()) return;

    List<dynamic> events = [];
    try {
      final decoded = jsonDecode(await eventsFile.readAsString());
      if (decoded is Map<String, dynamic> && decoded['events'] is List) {
        events = List<dynamic>.from(decoded['events'] as List);
      }
    } catch (_) {
      return;
    }

    final productIds = <String>{};
    for (final item in events) {
      if (item is! Map<String, dynamic>) continue;
      final id = (item['product_id'] as String?)?.trim();
      if (id == null || id.isEmpty) continue;
      productIds.add(id);
    }
    if (productIds.isEmpty) return;

    final db = await openDatabase(localDbPath);
    try {
      await db.transaction((txn) async {
        for (final productId in productIds) {
          await txn.delete(
            RecipeDatabaseService.ingredientProducts,
            where: 'id = ? AND is_default = 0',
            whereArgs: [productId],
          );
        }
      });
    } finally {
      await db.close();
    }
  }

  static const List<String> _tables = [
    RecipeDatabaseService.recipes,
    RecipeDatabaseService.recipeIngredients,
    RecipeDatabaseService.recipeSteps,
    RecipeDatabaseService.cookLogs,
    RecipeDatabaseService.recipeCategories,
    RecipeDatabaseService.ingredientCategories,
    RecipeDatabaseService.ingredientProducts,
    RecipeDatabaseService.ingredientDefaultDeletions,
    RecipeDatabaseService.shoppingTodos,
  ];
}
