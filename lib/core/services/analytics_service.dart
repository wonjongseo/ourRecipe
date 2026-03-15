import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();
  static const int _maxStringLength = 100;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    } catch (e, s) {
      LogManager.error(
        'Analytics initialize failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: _trim(userId));
    } catch (e, s) {
      LogManager.error('Analytics setUserId failed', error: e, stackTrace: s);
    }
  }

  Future<void> setCurrentScreen(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: _trim(screenName));
    } catch (e, s) {
      LogManager.error(
        'Analytics setCurrentScreen failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> recipeCreated({
    String? recipeId,
    String? category,
    int? ingredientCount,
    int? stepCount,
  }) async {
    await _log(
      'recipe_created',
      {
        'recipe_id': recipeId,
        'category': category,
        'ingredient_count': ingredientCount,
        'step_count': stepCount,
      },
    );
  }

  Future<void> recipeUpdated({
    String? recipeId,
    String? category,
    int? ingredientCount,
    int? stepCount,
  }) async {
    await _log(
      'recipe_updated',
      {
        'recipe_id': recipeId,
        'category': category,
        'ingredient_count': ingredientCount,
        'step_count': stepCount,
      },
    );
  }

  Future<void> recipeDeleted({
    String? recipeId,
    String? category,
  }) async {
    await _log(
      'recipe_deleted',
      {
        'recipe_id': recipeId,
        'category': category,
      },
    );
  }

  Future<void> ingredientCreated({
    String? ingredientId,
    String? category,
    bool? isDefault,
  }) async {
    await _log(
      'ingredient_created',
      {
        'ingredient_id': ingredientId,
        'category': category,
        'is_default': isDefault == null ? null : (isDefault ? 1 : 0),
      },
    );
  }

  Future<void> shoppingChecked({
    String? recipeId,
    String? ingredientName,
    bool? checked,
  }) async {
    await _log(
      'shopping_checked',
      {
        'recipe_id': recipeId,
        'ingredient_name': ingredientName,
        'checked': checked == null ? null : (checked ? 1 : 0),
      },
    );
  }

  Future<void> iCloudUploadStarted({
    int? recipeCount,
    int? ingredientCount,
  }) async {
    await _log(
      'icloud_upload_started',
      {
        'recipe_count': recipeCount,
        'ingredient_count': ingredientCount,
      },
    );
  }

  Future<void> iCloudUploadCompleted({
    int? recipeCount,
    int? ingredientCount,
  }) async {
    await _log(
      'icloud_upload_completed',
      {
        'recipe_count': recipeCount,
        'ingredient_count': ingredientCount,
      },
    );
  }

  Future<void> iCloudDownloadCompleted({
    int? recipeCount,
    int? ingredientCount,
  }) async {
    await _log(
      'icloud_download_completed',
      {
        'recipe_count': recipeCount,
        'ingredient_count': ingredientCount,
      },
    );
  }

  Future<void> premiumPurchaseStarted({
    String? productId,
    String? platform,
  }) async {
    await _log(
      'premium_purchase_started',
      {
        'product_id': productId,
        'platform': platform,
      },
    );
  }

  Future<void> premiumPurchaseCompleted({
    String? productId,
    String? platform,
  }) async {
    await _log(
      'premium_purchase_completed',
      {
        'product_id': productId,
        'platform': platform,
      },
    );
  }

  Future<void> logEvent(
    String eventName, {
    Map<String, Object?> parameters = const {},
  }) async {
    await _log(eventName, parameters);
  }

  Future<void> _log(
    String eventName,
    Map<String, Object?> parameters,
  ) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: _sanitizeParameters(parameters),
      );
    } catch (e, s) {
      LogManager.error(
        'Analytics event failed: $eventName',
        error: e,
        stackTrace: s,
      );
    }
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> parameters) {
    final result = <String, Object>{};
    parameters.forEach((key, value) {
      if (value == null) return;
      if (value is String) {
        result[key] = _trim(value);
        return;
      }
      if (value is num || value is bool) {
        result[key] = value;
      }
    });
    return result;
  }

  String _trim(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.length <= _maxStringLength) return normalized;
    return normalized.substring(0, _maxStringLength);
  }
}
