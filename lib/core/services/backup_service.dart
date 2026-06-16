import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo_list/features/task_list/data/models/task_model.dart';
import 'package:todo_list/features/task_list/data/models/category_model.dart';
import 'package:todo_list/features/task_list/data/models/sub_task_model.dart';

class BackupService {
  final Isar isar;

  BackupService(this.isar);

  Future<String> exportData() async {
    final tasks = await isar.taskModels.where().findAll();
    final categories = await isar.categoryModels.where().findAll();

    final data = {
      'categories': categories.map((c) => {
        'id': c.id,
        'name': c.name,
        'colorValue': c.colorValue,
      }).toList(),
      'tasks': tasks.map((t) => {
        'title': t.title,
        'description': t.description,
        'isCompleted': t.isCompleted,
        'orderIndex': t.orderIndex,
        'priority': t.priority.index,
        'createdAt': t.createdAt.toIso8601String(),
        'dueDate': t.dueDate?.toIso8601String(),
        'categoryId': t.category.value?.id,
        'subTasks': t.subTasks.map((st) => {
          'title': st.title,
          'isCompleted': st.isCompleted,
        }).toList(),
      }).toList(),
    };

    final jsonString = jsonEncode(data);
    
    // Save to documents directory
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/todo_backup.json');
    await file.writeAsString(jsonString);
    
    return file.path;
  }

  Future<bool> importData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/todo_backup.json');
      if (!await file.exists()) return false;

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final categoriesData = data['categories'] as List<dynamic>? ?? [];
      final tasksData = data['tasks'] as List<dynamic>? ?? [];

      await isar.writeTxn(() async {
        // Clear old data
        await isar.taskModels.clear();
        await isar.categoryModels.clear();

        // Import Categories
        final categoryMap = <int, CategoryModel>{};
        for (var cData in categoriesData) {
          final c = CategoryModel()
            ..name = cData['name']
            ..colorValue = cData['colorValue'];
          await isar.categoryModels.put(c);
          categoryMap[cData['id'] as int] = c;
        }

        // Import Tasks
        for (var tData in tasksData) {
          final t = TaskModel()
            ..title = tData['title']
            ..description = tData['description']
            ..isCompleted = tData['isCompleted']
            ..orderIndex = tData['orderIndex']
            ..priority = TaskPriority.values[tData['priority'] ?? 1]
            ..createdAt = DateTime.parse(tData['createdAt'])
            ..dueDate = tData['dueDate'] != null ? DateTime.parse(tData['dueDate']) : null;
            
          final subTasksData = tData['subTasks'] as List<dynamic>? ?? [];
          t.subTasks = subTasksData.map((st) => SubTaskModel()
            ..title = st['title']
            ..isCompleted = st['isCompleted']).toList();
          
          final categoryId = tData['categoryId'] as int?;
          if (categoryId != null && categoryMap.containsKey(categoryId)) {
            t.category.value = categoryMap[categoryId];
          }

          await isar.taskModels.put(t);
          await t.category.save();
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
