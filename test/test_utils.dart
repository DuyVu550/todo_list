import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:todo_list/features/task_list/data/models/task_model.dart';
import 'package:todo_list/features/task_list/data/models/category_model.dart';

Future<Isar> setupTestIsar() async {
  // Flutter test mặc định chặn HTTP request. Ta cần tạm tắt chặn để download
  final old = HttpOverrides.current;
  HttpOverrides.global = null;
  
  // Download và khởi tạo Isar Core cho môi trường test
  await Isar.initializeIsarCore(download: true);
  
  // Khôi phục chặn
  HttpOverrides.global = old;
  
  // Tạo thư mục tạm để lưu db test
  final dir = Directory.systemTemp.createTempSync('isar_test_${DateTime.now().millisecondsSinceEpoch}');
  
  return await Isar.open(
    [TaskModelSchema, CategoryModelSchema],
    directory: dir.path,
  );
}

ProviderContainer createContainer({
  ProviderContainer? parent,
  List<Override> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides,
    observers: observers,
  );
  return container;
}
