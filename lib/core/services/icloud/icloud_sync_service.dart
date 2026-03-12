import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/services/icloud/app_data_path_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_settings_service.dart';
import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/feature/recipes/models/recipe_model.dart';
import 'package:our_recipe/feature/recipes/repository/cook_log_repository.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/ingredient_product_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_category_repository.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_repository.dart';
import 'package:our_recipe/feature/shopping/repository/shopping_todo_repository.dart';

/// CloudKit 동기화 facade.
///
/// 구조는 단순하다.
/// 1. 앱은 계속 로컬 SQLite와 로컬 이미지 파일만 사용한다.
/// 2. iCloud 공유가 ON이면 현재 로컬 상태를 CloudKit에 스냅샷으로 올린다.
/// 3. 다른 기기는 그 스냅샷을 받아 자기 로컬 SQLite와 로컬 이미지 폴더에 반영한다.
///
/// 즉, 앱은 CloudKit를 직접 조회하며 동작하지 않는다.
/// CloudKit는 "공유 백엔드", SQLite는 "실제 앱 런타임 저장소" 역할을 맡는다.
class ICloudSyncService {
  static const Duration _channelTimeout = Duration(minutes: 3);
  ICloudSyncService({
    ICloudSyncSettingsService? settings,
    RecipeRepository? recipeRepository,
    RecipeCategoryRepository? recipeCategoryRepository,
    IngredientCategoryRepository? ingredientCategoryRepository,
    IngredientProductRepository? ingredientProductRepository,
    CookLogRepository? cookLogRepository,
    ShoppingTodoRepository? shoppingTodoRepository,
  }) : _settings = settings ?? ICloudSyncSettingsService(),
       _recipeRepository = recipeRepository ?? RecipeRepository(),
       _recipeCategoryRepository =
           recipeCategoryRepository ?? RecipeCategoryRepository(),
       _ingredientCategoryRepository =
           ingredientCategoryRepository ?? IngredientCategoryRepository(),
       _ingredientProductRepository =
           ingredientProductRepository ?? IngredientProductRepository(),
       _cookLogRepository = cookLogRepository ?? CookLogRepository(),
       _shoppingTodoRepository =
           shoppingTodoRepository ?? ShoppingTodoRepository();

  static const MethodChannel _channel = MethodChannel('our_recipe/icloud_path');
  static Future<void> _syncQueue = Future<void>.value();

  final ICloudSyncSettingsService _settings;
  final RecipeRepository _recipeRepository;
  final RecipeCategoryRepository _recipeCategoryRepository;
  final IngredientCategoryRepository _ingredientCategoryRepository;
  final IngredientProductRepository _ingredientProductRepository;
  final CookLogRepository _cookLogRepository;
  final ShoppingTodoRepository _shoppingTodoRepository;

  Future<bool> isEnabledOnIOS() async {
    if (!Platform.isIOS) return false;
    return _settings.isEnabled();
  }

  /// CloudKit 스냅샷을 내려받아 현재 기기의 로컬 SQLite와 이미지 폴더를 갱신한다.
  Future<void> pullIfEnabled() async {
    if (!await isEnabledOnIOS()) return;
    return _runExclusive(_pullInternal);
  }

  /// 현재 로컬 상태를 CloudKit에 올린 뒤, 다시 한 번 받아 로컬을 정렬한다.
  ///
  /// 마지막 pull 을 한 번 더 두는 이유:
  /// - 업로드 과정에서 이미지/스냅샷 저장이 완료된 최종 상태를
  ///   현재 기기 로컬에도 동일하게 맞추기 위해서다.
  Future<void> pushPullIfEnabled() async {
    if (!await isEnabledOnIOS()) return;
    return _runExclusive(_pushPullInternal);
  }

  /// 현재 로컬 상태를 CloudKit에 업로드만 한다.
  /// 현재 기기 UI는 로컬 SQLite를 기준으로 즉시 갱신하고,
  /// 다른 기기는 다음 pull 시 최신 데이터를 받는다.
  Future<void> pushIfEnabled() async {
    if (!await isEnabledOnIOS()) return;
    return _runExclusive(_pushInternal);
  }

  /// 저장/수정/삭제 직후 UI를 막지 않기 위한 백그라운드 업로드.
  void schedulePushIfEnabled() {
    unawaited(
      pushIfEnabled().catchError((error, stackTrace) {
        LogManager.error(
          'CloudKit background push failed',
          error: error,
          stackTrace: stackTrace is StackTrace ? stackTrace : null,
        );
      }),
    );
  }

  /// CloudKit 전체 데이터 삭제.
  ///
  /// 로컬 SQLite는 건드리지 않는다.
  Future<void> clearCloudDataIfEnabled() async {
    if (!await isEnabledOnIOS()) return;
    return _runExclusive(() async {
      try {
        await _channel
            .invokeMethod<void>('clearCloudKitData')
            .timeout(_channelTimeout);
      } catch (e, s) {
        LogManager.error('CloudKit clear failed', error: e, stackTrace: s);
        rethrow;
      }
    });
  }

  Future<void> _pullInternal() async {
    try {
      final imageDir = await AppDataPathService.getRecipeImagesDirectoryPath();
      LogManager.debug('CloudKit pull start');
      final result = await _channel
          .invokeMapMethod<String, dynamic>('downloadCloudKitSnapshot', {
            'imagesDirPath': imageDir,
          })
          .timeout(_channelTimeout);
      if (result == null || result['found'] != true) {
        return;
      }

      final snapshotPath = (result['snapshotPath'] as String?)?.trim();
      if (snapshotPath == null || snapshotPath.isEmpty) {
        return;
      }
      LogManager.debug('CloudKit pull snapshot received: $snapshotPath');

      final snapshotFile = File(snapshotPath);
      if (!await snapshotFile.exists()) {
        return;
      }

      final decoded = jsonDecode(await snapshotFile.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final localSnapshot = await _buildSnapshot();
      final mergedSnapshot = _mergeSnapshots(
        current: localSnapshot,
        incoming: decoded,
      );

      // snapshot 적용 직전에만 DB 캐시를 닫고 다시 열어 반영 충돌을 줄인다.
      await RecipeDatabaseService.reset();
      await _applySnapshot(mergedSnapshot);
      LogManager.debug('CloudKit pull snapshot applied');
      LogManager.debug(
        'CloudKit pull recipe cover names: '
        '${_readRecipeList(mergedSnapshot, 'recipes').map((e) => '${e.id}:${_portableImagePath(e.coverImagePath)}').toList()}',
      );
      await RecipeDatabaseService.reset();
    } catch (e, s) {
      LogManager.error('CloudKit pull failed', error: e, stackTrace: s);
      await RecipeDatabaseService.reset();
      rethrow;
    }
  }

  Future<void> _pushPullInternal() async {
    try {
      await _pushInternal();
      await _pullInternal();
    } catch (e, s) {
      LogManager.error('CloudKit push failed', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _pushInternal() async {
    try {
      final localSnapshot = await _buildSnapshot();
      final remoteSnapshot = await _downloadSnapshotPayloadOnly();
      final snapshot = _mergeSnapshots(
        current: remoteSnapshot,
        incoming: localSnapshot,
      );
      final tempDir = await getTemporaryDirectory();
      final snapshotFile = File(
        p.join(tempDir.path, 'cloudkit_snapshot_upload.json'),
      );
      await snapshotFile.writeAsString(jsonEncode(snapshot));

      final imagePaths = await _collectLocalImagePaths(snapshot);
      LogManager.debug(
        'CloudKit push start: '
        'recipes=${(snapshot['recipes'] as List<dynamic>? ?? const []).length}, '
        'cookLogs=${(snapshot['cookLogs'] as List<dynamic>? ?? const []).length}, '
        'ingredientProducts=${(snapshot['ingredientProducts'] as List<dynamic>? ?? const []).length}, '
        'images=${imagePaths.length}',
      );
      LogManager.debug(
        'CloudKit push image names: ${imagePaths.map(p.basename).toList()}',
      );
      await _channel
          .invokeMethod<void>('uploadCloudKitSnapshot', {
            'snapshotPath': snapshotFile.path,
            'imagePaths': imagePaths,
          })
          .timeout(_channelTimeout);
      LogManager.debug('CloudKit push upload finished');
    } catch (e, s) {
      LogManager.error('CloudKit push failed', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _downloadSnapshotPayloadOnly() async {
    Map<String, dynamic>? result;
    try {
      result = await _channel
          .invokeMapMethod<String, dynamic>('downloadCloudKitSnapshotPayload')
          .timeout(_channelTimeout);
    } on MissingPluginException {
      final imageDir = await AppDataPathService.getRecipeImagesDirectoryPath();
      result = await _channel
          .invokeMapMethod<String, dynamic>('downloadCloudKitSnapshot', {
            'imagesDirPath': imageDir,
          })
          .timeout(_channelTimeout);
    }
    if (result == null || result['found'] != true) {
      return <String, dynamic>{};
    }

    final snapshotPath = (result['snapshotPath'] as String?)?.trim();
    if (snapshotPath == null || snapshotPath.isEmpty) {
      return <String, dynamic>{};
    }

    final snapshotFile = File(snapshotPath);
    if (!await snapshotFile.exists()) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(await snapshotFile.readAsString());
    if (decoded is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }
    return decoded;
  }

  Future<void> _runExclusive(Future<void> Function() action) async {
    final completer = Completer<void>();
    final previous = _syncQueue;
    _syncQueue = completer.future;
    try {
      await previous;
      await action();
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<Map<String, dynamic>?> getCloudStatus() async {
    if (!Platform.isIOS) return null;
    return _channel.invokeMapMethod<String, dynamic>('getICloudStatus');
  }

  Future<Map<String, dynamic>> _buildSnapshot() async {
    final recipes = await _recipeRepository.fetchRecipes();
    final cookLogs = await _cookLogRepository.fetchCookLogs();
    final recipeCategories = await _recipeCategoryRepository.fetchCategories();
    final ingredientCategories =
        await _ingredientCategoryRepository.fetchCustomCategories();
    final ingredientProducts =
        await _ingredientProductRepository.fetchCustomProductsForSync();
    final deletedDefaultIds =
        await _ingredientProductRepository.fetchDeletedDefaultIdsForSync();
    final shoppingChecked = await _shoppingTodoRepository.fetchCheckedKeys();
    final deletedRecipeTombstones =
        await _settings.getDeletedRecipeTombstones();

    return {
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'recipes': recipes.map(_portableRecipeJson).toList(),
      'cookLogs': cookLogs.map(_portableCookLogJson).toList(),
      'recipeCategories': recipeCategories,
      'ingredientCategories': ingredientCategories,
      'ingredientProducts': ingredientProducts.map((e) => e.toJson()).toList(),
      'deletedRecipeTombstones': deletedRecipeTombstones,
      'deletedDefaultIngredientIds': deletedDefaultIds.toList(),
      'shoppingCheckedKeys': shoppingChecked.toList(),
    };
  }

  Map<String, dynamic> _mergeSnapshots({
    required Map<String, dynamic> current,
    required Map<String, dynamic> incoming,
  }) {
    final mergedRecipes = _mergeRecipes(
      _readRecipeList(current, 'recipes'),
      _readRecipeList(incoming, 'recipes'),
    );
    final mergedCookLogs = _mergeCookLogs(
      _readCookLogList(current, 'cookLogs'),
      _readCookLogList(incoming, 'cookLogs'),
    );
    final mergedRecipeCategories = _mergeStringLists(
      _readStringList(current, 'recipeCategories'),
      _readStringList(incoming, 'recipeCategories'),
    );
    final mergedIngredientCategories = _mergeStringLists(
      _readStringList(current, 'ingredientCategories'),
      _readStringList(incoming, 'ingredientCategories'),
    );
    final mergedIngredientProducts = _mergeIngredientProducts(
      _readIngredientProductList(current, 'ingredientProducts'),
      _readIngredientProductList(incoming, 'ingredientProducts'),
    );
    final mergedDeletedRecipeTombstones = _mergeDeletedRecipeTombstones(
      _readDeletedRecipeTombstones(current),
      _readDeletedRecipeTombstones(incoming),
    );
    final visibleRecipes = _applyDeletedRecipeTombstones(
      mergedRecipes,
      mergedDeletedRecipeTombstones,
    );
    final mergedDeletedDefaultIds = _mergeStringLists(
      _readStringList(current, 'deletedDefaultIngredientIds'),
      _readStringList(incoming, 'deletedDefaultIngredientIds'),
    );
    final mergedShoppingChecked = {
      ..._readStringList(current, 'shoppingCheckedKeys'),
      ..._readStringList(incoming, 'shoppingCheckedKeys'),
    }.toList();

    return {
      'version': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'recipes': visibleRecipes.map(_portableRecipeJson).toList(),
      'cookLogs': mergedCookLogs.map(_portableCookLogJson).toList(),
      'recipeCategories': mergedRecipeCategories,
      'ingredientCategories': mergedIngredientCategories,
      'ingredientProducts':
          mergedIngredientProducts.map((e) => e.toJson()).toList(),
      'deletedRecipeTombstones': mergedDeletedRecipeTombstones.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'deletedDefaultIngredientIds': mergedDeletedDefaultIds,
      'shoppingCheckedKeys': mergedShoppingChecked,
    };
  }

  List<RecipeModel> _readRecipeList(Map<String, dynamic> source, String key) {
    return (source[key] as List<dynamic>? ?? [])
        .map((e) => RecipeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<CookLogModel> _readCookLogList(Map<String, dynamic> source, String key) {
    return (source[key] as List<dynamic>? ?? [])
        .map((e) => CookLogModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<IngredientProductModel> _readIngredientProductList(
    Map<String, dynamic> source,
    String key,
  ) {
    return (source[key] as List<dynamic>? ?? [])
        .map(
          (e) => IngredientProductModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  List<String> _readStringList(Map<String, dynamic> source, String key) {
    return (source[key] as List<dynamic>? ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, DateTime> _readDeletedRecipeTombstones(
    Map<String, dynamic> source,
  ) {
    final raw =
        (source['deletedRecipeTombstones'] as Map<dynamic, dynamic>?) ?? const {};
    final result = <String, DateTime>{};
    for (final entry in raw.entries) {
      final id = entry.key.toString().trim();
      if (id.isEmpty) continue;
      final deletedAt = DateTime.tryParse(entry.value?.toString() ?? '');
      if (deletedAt == null) continue;
      result[id] = deletedAt;
    }
    return result;
  }

  List<String> _mergeStringLists(List<String> current, List<String> incoming) {
    return {...current, ...incoming}.toList();
  }

  List<RecipeModel> _mergeRecipes(
    List<RecipeModel> current,
    List<RecipeModel> incoming,
  ) {
    final byId = <String, RecipeModel>{};
    for (final recipe in current) {
      byId[recipe.id] = recipe;
    }
    for (final recipe in incoming) {
      final existing = byId[recipe.id];
      if (existing == null || recipe.updatedAt.isAfter(existing.updatedAt)) {
        byId[recipe.id] = recipe;
      }
    }
    final results = byId.values.toList();
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  Map<String, DateTime> _mergeDeletedRecipeTombstones(
    Map<String, DateTime> current,
    Map<String, DateTime> incoming,
  ) {
    final merged = <String, DateTime>{...current};
    for (final entry in incoming.entries) {
      final existing = merged[entry.key];
      if (existing == null || entry.value.isAfter(existing)) {
        merged[entry.key] = entry.value;
      }
    }
    return merged;
  }

  List<RecipeModel> _applyDeletedRecipeTombstones(
    List<RecipeModel> recipes,
    Map<String, DateTime> tombstones,
  ) {
    return recipes.where((recipe) {
      final deletedAt = tombstones[recipe.id];
      if (deletedAt == null) return true;
      return recipe.updatedAt.isAfter(deletedAt);
    }).toList();
  }

  List<CookLogModel> _mergeCookLogs(
    List<CookLogModel> current,
    List<CookLogModel> incoming,
  ) {
    final byId = <String, CookLogModel>{};
    for (final log in current) {
      byId[log.id] = log;
    }
    for (final log in incoming) {
      final existing = byId[log.id];
      if (existing == null || log.cookedAt.isAfter(existing.cookedAt)) {
        byId[log.id] = log;
      }
    }
    final results = byId.values.toList();
    results.sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
    return results;
  }

  List<IngredientProductModel> _mergeIngredientProducts(
    List<IngredientProductModel> current,
    List<IngredientProductModel> incoming,
  ) {
    final byId = <String, IngredientProductModel>{};
    for (final product in current) {
      byId[product.id] = product;
    }
    for (final product in incoming) {
      byId[product.id] = product;
    }
    return byId.values.toList();
  }

  Map<String, dynamic> _portableRecipeJson(RecipeModel recipe) {
    final json = recipe.toJson();
    json['coverImagePath'] = _portableImagePath(recipe.coverImagePath);
    final steps =
        (json['steps'] as List<dynamic>? ?? []).map((item) {
          final step = Map<String, dynamic>.from(item as Map<String, dynamic>);
          step['imagePath'] = _portableImagePath(step['imagePath'] as String?);
          return step;
        }).toList();
    json['steps'] = steps;
    return json;
  }

  Map<String, dynamic> _portableCookLogJson(CookLogModel log) {
    final json = log.toJson();
    json['resultImagePath'] = _portableImagePath(log.resultImagePath);
    return json;
  }

  String? _portableImagePath(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return p.basename(trimmed);
  }

  Future<List<String>> _collectLocalImagePaths(
    Map<String, dynamic> snapshot,
  ) async {
    final docsPath = await AppDataPathService.getRecipeImagesDirectoryPath();
    final results = <String>[];

    void addIfExists(String? fileName) {
      if (fileName == null || fileName.trim().isEmpty) return;
      final file = File(p.join(docsPath, fileName));
      if (file.existsSync()) {
        results.add(file.path);
      }
    }

    final recipes = (snapshot['recipes'] as List<dynamic>? ?? []);
    for (final item in recipes) {
      final recipe = item as Map<String, dynamic>;
      addIfExists(recipe['coverImagePath'] as String?);
      for (final step in recipe['steps'] as List<dynamic>? ?? const []) {
        addIfExists((step as Map<String, dynamic>)['imagePath'] as String?);
      }
    }

    final logs = (snapshot['cookLogs'] as List<dynamic>? ?? []);
    for (final item in logs) {
      addIfExists((item as Map<String, dynamic>)['resultImagePath'] as String?);
    }

    return results.toSet().toList();
  }

  Future<void> _applySnapshot(Map<String, dynamic> snapshot) async {
    final deletedRecipeTombstones = _readDeletedRecipeTombstones(snapshot);
    final recipes = _applyDeletedRecipeTombstones(
      _readRecipeList(snapshot, 'recipes'),
      deletedRecipeTombstones,
    );
    final cookLogs = _readCookLogList(snapshot, 'cookLogs');
    final recipeCategories = _readStringList(snapshot, 'recipeCategories');
    final ingredientCategories = _readStringList(
      snapshot,
      'ingredientCategories',
    );
    final ingredientProducts = _readIngredientProductList(
      snapshot,
      'ingredientProducts',
    );
    final deletedDefaultIds = _readStringList(
      snapshot,
      'deletedDefaultIngredientIds',
    );
    final shoppingChecked = _readStringList(
      snapshot,
      'shoppingCheckedKeys',
    ).toSet();

    await _recipeCategoryRepository.saveCategories(recipeCategories);
    await _ingredientCategoryRepository.saveCustomCategories(
      ingredientCategories,
    );
    await _ingredientProductRepository.saveProducts(ingredientProducts);
    await _settings.saveDeletedRecipeTombstones(
      deletedRecipeTombstones.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    );
    await _ingredientProductRepository.saveDeletedDefaultIdsForSync(
      deletedDefaultIds,
    );
    await _recipeRepository.saveRecipes(recipes);
    await _cookLogRepository.saveCookLogs(cookLogs);
    await _shoppingTodoRepository.saveCheckedKeys(shoppingChecked);
  }
}
