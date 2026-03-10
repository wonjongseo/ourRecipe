import 'dart:io';

import 'package:our_recipe/core/services/icloud/icloud_sync_migration_service.dart';
import 'package:our_recipe/core/services/icloud/icloud_sync_settings_service.dart';
import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';

/// iCloud 동기화 실행을 공통화한 서비스.
///
/// 다른 프로젝트에서도 아래 세 가지만 바꾸면 재사용하기 쉽도록 구성했다.
/// - 토글 상태 저장 서비스
/// - 실제 마이그레이션/병합 서비스
/// - DB reset 서비스
class ICloudSyncService {
  ICloudSyncService({
    ICloudSyncSettingsService? settings,
    ICloudSyncMigrationService? migration,
  }) : _settings = settings ?? ICloudSyncSettingsService(),
       _migration = migration ?? ICloudSyncMigrationService();

  final ICloudSyncSettingsService _settings;
  final ICloudSyncMigrationService _migration;

  /// 다른 기기에서 바뀐 내용을 현재 기기로 가져온다.
  /// = iCloud -> local
  Future<bool> isEnabledOnIOS() async {
    if (!Platform.isIOS) return false;
    return _settings.isEnabled();
  }

  /// 다른 기기에서 바뀐 내용을 현재 기기로 가져온다.
  /// = iCloud -> local
  Future<void> pullIfEnabled() async {
    if (!await isEnabledOnIOS()) return;
    await RecipeDatabaseService.reset();
    await _migration.syncFromICloudToLocalMerge();
    await RecipeDatabaseService.reset();
  }

  /// 현재 기기 변경 + iCloud 변경을 서로 맞춘다.
  /// = pull -> push -> pull
  ///
  /// 이 순서를 쓰는 이유:
  /// 1. 먼저 pull 해서 로컬이 이미 최신 클라우드 내용을 포함하게 만들고
  /// 2. 그 상태의 로컬을 다시 iCloud로 push 하면
  /// 3. "한쪽 데이터만 남는" 현상을 줄일 수 있기 때문이다.
  Future<void> pushPullIfEnabled() async {
    if (!await isEnabledOnIOS()) return;
    await RecipeDatabaseService.reset();
    await _migration.syncBidirectionalMerge();
    await RecipeDatabaseService.reset();
  }

  Future<void> deleteRecipeIfEnabled(String recipeId) async {
    if (!await isEnabledOnIOS()) return;
    await RecipeDatabaseService.reset();
    await _migration.deleteRecipeFromICloud(recipeId);
    await RecipeDatabaseService.reset();
  }

  Future<void> upsertIngredientIfEnabled(IngredientProductModel product) async {
    if (!await isEnabledOnIOS()) return;
    await RecipeDatabaseService.reset();
    await _migration.upsertIngredientProductToICloud(product);
    await RecipeDatabaseService.reset();
  }

  Future<void> deleteIngredientIfEnabled(String productId) async {
    if (!await isEnabledOnIOS()) return;
    await RecipeDatabaseService.reset();
    await _migration.deleteIngredientProductFromICloud(productId);
    await RecipeDatabaseService.reset();
  }
}
