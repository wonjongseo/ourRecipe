import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:our_recipe/core/common/app_colors.dart';
import 'package:our_recipe/core/common/app_strings.dart';
import 'package:our_recipe/core/helpers/log_manager.dart';
import 'package:our_recipe/core/helpers/snackbar_helper.dart';
import 'package:our_recipe/core/widgets/ad_banner_bottom_sheet.dart';
import 'package:our_recipe/core/widgets/custom_text_form_field.dart';
import 'package:our_recipe/feature/recipes/repository/recipe_category_repository.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({
    super.key,
    required this.isCameToEditRecipeScreen,
  });
  static String name = '/category_management';
  final bool isCameToEditRecipeScreen;
  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _repository = Get.find<RecipeCategoryRepository>();
  final _controller = TextEditingController();
  final _categories = <String>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final values = await _repository.fetchCategories();
      values.sort();
      if (!mounted) return;
      setState(() {
        _categories
          ..clear()
          ..addAll(values);
      });
    } catch (e, s) {
      LogManager.error(
        'Load recipe categories failed',
        error: e,
        stackTrace: s,
      );
      SnackBarHelper.showErrorSnackBar(AppStrings.dbLoadFailed.tr);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _repository.addCategory(value);
      _controller.clear();
      await _loadCategories();
    } catch (e, s) {
      LogManager.error('Add recipe category failed', error: e, stackTrace: s);
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeCategory(String category) async {
    setState(() => _isLoading = true);
    try {
      await _repository.removeCategory(category);
      await _loadCategories();
    } catch (e, s) {
      LogManager.error(
        'Remove recipe category failed',
        error: e,
        stackTrace: s,
      );
      SnackBarHelper.showErrorSnackBar(AppStrings.dbSaveFailed.tr);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AdBannerBottomSheet(),
      appBar: AppBar(title: Text(AppStrings.categoryManagement.tr)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: _controller,
                    hintText: AppStrings.categoryName.tr,
                    onFieldSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _addCategory,
                    child: Text(AppStrings.add.tr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator.adaptive())
                      : _categories.isEmpty
                      ? Center(
                        child: Text(
                          AppStrings.noRegisteredCategory.tr,
                          style: TextStyle(
                            color: AppColors.noRegisteredItemColor,
                          ),
                        ),
                      )
                      : ListView.separated(
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final category = _categories[index];
                          return ListTile(
                            onTap:
                                widget.isCameToEditRecipeScreen
                                    ? () => Get.back(result: category)
                                    : null,
                            tileColor: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFD5D9DF)),
                            ),
                            title: Text(category),
                            trailing: IconButton(
                              onPressed: () => _removeCategory(category),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
