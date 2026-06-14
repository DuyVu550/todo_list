import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/category_model.dart';
import '../../../../core/database/isar_provider.dart';

class CategoryNotifier extends AutoDisposeStreamNotifier<List<CategoryModel>> {
  @override
  Stream<List<CategoryModel>> build() {
    final isar = ref.watch(isarProvider);
    return isar.categoryModels.where().watch(fireImmediately: true);
  }

  Future<void> addCategory(String name, {int colorValue = 0xFF2196F3}) async {
    final isar = ref.read(isarProvider);
    final category = CategoryModel()
      ..name = name
      ..colorValue = colorValue;

    await isar.writeTxn(() async {
      await isar.categoryModels.put(category);
    });
  }

  Future<void> updateCategory(Id categoryId, String name, {int colorValue = 0xFF2196F3}) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      final category = await isar.categoryModels.get(categoryId);
      if (category != null) {
        category.name = name;
        category.colorValue = colorValue;
        await isar.categoryModels.put(category);
      }
    });
  }

  Future<void> deleteCategory(Id categoryId) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.categoryModels.delete(categoryId);
    });
  }
}

final categoryListProvider = AutoDisposeStreamNotifierProvider<CategoryNotifier, List<CategoryModel>>(
  () => CategoryNotifier(),
);
