import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/services/recipe_database_service.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_category_catalog.dart';
import 'package:our_recipe/feature/recipes/models/ingredient_product_model.dart';
import 'package:sqflite/sqflite.dart';

class IngredientProductRepository {
  IngredientProductRepository({RecipeDatabaseService? database})
    : _database = database ?? RecipeDatabaseService();

  final RecipeDatabaseService _database;
  static final Map<String, List<IngredientProductModel>>
  _defaultProductsCacheByLang = {};
  static final Map<String, List<IngredientProductGroup>>
  _defaultGroupedCacheByLang = {};

  Future<List<IngredientProductModel>> fetchProducts() async {
    final defaults = await _loadDefaultProducts();
    final deletedDefaultIds = await _fetchDeletedDefaultIds();
    final customProducts = await _fetchCustomProducts();

    final byId = <String, IngredientProductModel>{};
    for (final item in defaults) {
      if (deletedDefaultIds.contains(item.id)) continue;
      byId[item.id] = item;
    }
    for (final item in customProducts) {
      byId[item.id] = item;
    }
    return byId.values.toList();
  }

  Future<List<IngredientProductModel>> _fetchCustomProducts() async {
    final db = await _database.db;
    final rows = await db.query(
      RecipeDatabaseService.ingredientProducts,
      where: 'is_default = 0',
    );
    return rows.map(_productFromRow).toList();
  }

  Future<Set<String>> _fetchDeletedDefaultIds() async {
    final db = await _database.db;
    final rows = await db.query(RecipeDatabaseService.ingredientDefaultDeletions);
    return rows.map((row) => row['id'] as String).toSet();
  }

  Future<List<IngredientProductModel>> _loadDefaultProducts() async {
    final langCode = _resolvedLanguageCode();
    final cached = _defaultProductsCacheByLang[langCode];
    if (cached != null) return cached;
    final grouped = await _loadDefaultGroupedProducts();
    final products = <IngredientProductModel>[];
    for (final group in grouped) {
      for (final item in group.items) {
        products.addAll(item.products);
      }
    }
    _defaultProductsCacheByLang[langCode] = products;
    return products;
  }

  Future<List<IngredientProductGroup>> fetchGroupedProducts() async {
    final defaults = await _loadDefaultGroupedProducts();
    final deletedDefaultIds = await _fetchDeletedDefaultIds();
    final customProducts = await _fetchCustomProducts();

    final filteredDefaults = <IngredientProductGroup>[];
    for (final group in defaults) {
      final filteredItems = <IngredientProductSubGroup>[];
      for (final item in group.items) {
        final filteredProducts =
            item.products
                .where((product) => !deletedDefaultIds.contains(product.id))
                .toList();
        if (filteredProducts.isEmpty) continue;
        filteredItems.add(
          IngredientProductSubGroup(
            id: item.id,
            name: item.name,
            products: filteredProducts,
          ),
        );
      }
      if (filteredItems.isEmpty) continue;
      filteredDefaults.add(
        IngredientProductGroup(
          id: group.id,
          name: group.name,
          items: filteredItems,
        ),
      );
    }

    if (customProducts.isEmpty) return filteredDefaults;

    final customByCategory = <String, List<IngredientProductModel>>{};
    for (final product in customProducts) {
      final category =
          product.category.trim().isEmpty ? 'Custom' : product.category.trim();
      customByCategory
          .putIfAbsent(category, () => <IngredientProductModel>[])
          .add(product);
    }

    final customGroups =
        customByCategory.entries.map((entry) {
          return IngredientProductGroup(
            id: 'custom_${entry.key}',
            name: entry.key,
            items: [
              IngredientProductSubGroup(
                id: 'custom',
                name: entry.key,
                products: entry.value,
              ),
            ],
          );
        }).toList();

    return [...filteredDefaults, ...customGroups];
  }

  Future<List<IngredientProductGroup>> _loadDefaultGroupedProducts() async {
    final langCode = _resolvedLanguageCode();
    final cached = _defaultGroupedCacheByLang[langCode];
    if (cached != null) return cached;
    final assetPaths = <String>[_assetPathForLang(langCode)];
    const jpAssetPath = 'assets/json/foods_nutrients_jp.json';
    if (assetPaths.first != jpAssetPath) {
      assetPaths.add(jpAssetPath);
    }

    for (final assetPath in assetPaths) {
      final grouped = await _loadGroupedFromAsset(assetPath);
      if (grouped.isEmpty) continue;
      _defaultGroupedCacheByLang[langCode] = grouped;
      return grouped;
    }

    _defaultGroupedCacheByLang[langCode] = const [];
    return const [];
  }

  Future<List<IngredientProductGroup>> _loadGroupedFromAsset(
    String assetPath,
  ) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];

      final grouped = <IngredientProductGroup>[];
      for (final group in decoded) {
        final groupMap = group as Map<String, dynamic>;
        final category = (groupMap['categoryName'] as String? ?? '').trim();
        final categoryCode =
            (groupMap['categoryCode'] as String? ?? category).trim();
        final items = (groupMap['items'] as List<dynamic>? ?? []);
        final subGroups = <IngredientProductSubGroup>[];
        for (final item in items) {
          final itemMap = item as Map<String, dynamic>;
          final itemName = (itemMap['name'] as String? ?? '').trim();
          final foods = (itemMap['foods'] as List<dynamic>? ?? []);
          final itemProducts = <IngredientProductModel>[];
          for (final food in foods) {
            final foodMap = food as Map<String, dynamic>;
            final foodCode = (foodMap['foodCode'] as String? ?? '').trim();
            if (foodCode.isEmpty) continue;
            final foodName = (foodMap['name'] as String? ?? '').trim();
            final name = '$itemName $foodName'.trim();
            itemProducts.add(
              IngredientProductModel(
                id: foodCode,
                isDefault: true,
                name: name,
                category: category,
                manufacturer: '',
                price: 0,
                baseGram: 100,
                kcal: (foodMap['kcal'] as num?)?.toDouble(),
                water: (foodMap['water'] as num?)?.toDouble(),
                protein: (foodMap['protein'] as num?)?.toDouble(),
                fat: (foodMap['fat'] as num?)?.toDouble(),
                carbohydrate: (foodMap['carbohydrate'] as num?)?.toDouble(),
                fiber: (foodMap['fiber'] as num?)?.toDouble(),
                ash: (foodMap['ash'] as num?)?.toDouble(),
                sodium: (foodMap['sodium'] as num?)?.toDouble(),
              ),
            );
          }
          if (itemProducts.isEmpty) continue;
          final itemId = (itemMap['indexCode'] as String? ?? itemName).trim();
          subGroups.add(
            IngredientProductSubGroup(
              id: itemId,
              name: itemName,
              products: itemProducts,
            ),
          );
        }
        if (subGroups.isEmpty) continue;
        grouped.add(
          IngredientProductGroup(
            id: categoryCode,
            name: category,
            items: subGroups,
          ),
        );
      }
      return grouped;
    } catch (_) {
      return const [];
    }
  }

  String _resolvedLanguageCode() {
    final appLang = Get.locale?.languageCode.trim().toLowerCase();
    if (appLang != null && appLang.isNotEmpty) return appLang;
    return PlatformDispatcher.instance.locale.languageCode
        .trim()
        .toLowerCase();
  }

  String _assetPathForLang(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return 'assets/json/foods_nutrients_ko.json';
      case 'en':
        return 'assets/json/foods_nutrients_en.json';
      case 'ja':
      default:
        return 'assets/json/foods_nutrients_jp.json';
    }
  }

  Future<void> saveProducts(List<IngredientProductModel> products) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.delete(
        RecipeDatabaseService.ingredientProducts,
        where: 'is_default = 0',
      );
      for (final product in products) {
        await txn.insert(
          RecipeDatabaseService.ingredientProducts,
          _productToRow(product, isDefault: false),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> saveProduct(IngredientProductModel product) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      await txn.insert(
        RecipeDatabaseService.ingredientProducts,
        _productToRow(product, isDefault: false),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        RecipeDatabaseService.ingredientDefaultDeletions,
        where: 'id = ?',
        whereArgs: [product.id],
      );
    });
  }

  Future<void> deleteProduct(String productId) async {
    final db = await _database.db;
    final deleted = await db.delete(
      RecipeDatabaseService.ingredientProducts,
      where: 'id = ? AND is_default = 0',
      whereArgs: [productId],
    );
    if (deleted > 0) return;
    await db.insert(
      RecipeDatabaseService.ingredientDefaultDeletions,
      {'id': productId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  IngredientProductModel _productFromRow(Map<String, Object?> row) {
    return IngredientProductModel(
      id: row['id'] as String,
      isDefault: false,
      name: (row['name'] as String? ?? '').trim(),
      category: (row['category'] as String? ?? '').trim(),
      manufacturer: (row['manufacturer'] as String? ?? '').trim(),
      price: (row['price'] as num?)?.toDouble() ?? 0,
      baseGram: (row['base_gram'] as num?)?.toDouble() ?? 0,
      kcal: (row['kcal'] as num?)?.toDouble(),
      water: (row['water'] as num?)?.toDouble(),
      protein: (row['protein'] as num?)?.toDouble(),
      fat: (row['fat'] as num?)?.toDouble(),
      carbohydrate: (row['carbohydrate'] as num?)?.toDouble(),
      fiber: (row['fiber'] as num?)?.toDouble(),
      ash: (row['ash'] as num?)?.toDouble(),
      sodium: (row['sodium'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> _productToRow(
    IngredientProductModel product, {
    required bool isDefault,
  }) {
    return {
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
      'is_default': isDefault ? 1 : 0,
    };
  }
}

class IngredientProductGroup {
  final String id;
  final String name;
  final List<IngredientProductSubGroup> items;

  const IngredientProductGroup({
    required this.id,
    required this.name,
    required this.items,
  });
}

class IngredientProductSubGroup {
  final String id;
  final String name;
  final List<IngredientProductModel> products;

  const IngredientProductSubGroup({
    required this.id,
    required this.name,
    required this.products,
  });
}
