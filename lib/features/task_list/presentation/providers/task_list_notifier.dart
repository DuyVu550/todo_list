import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/task_model.dart';
import '../../data/models/category_model.dart';
import '../../../../core/database/isar_provider.dart';
import '../../../../core/services/notification_service.dart';

enum TaskFilter { all, completed, incomplete }
enum TaskSort { custom, newest, dueDate }


class TaskListNotifier extends StreamNotifier<List<TaskModel>> {
  @override
  Stream<List<TaskModel>> build() {
    final isar = ref.watch(isarProvider);
    
    return isar.taskModels.where().watch(fireImmediately: true).asyncMap((tasks) async {
      for (var task in tasks) {
        await task.category.load();
      }
      return tasks;
    });
  }

  Future<void> addTask(String title, {String? description, DateTime? dueDate, CategoryModel? category}) async {
    final isar = ref.read(isarProvider);
    
    final currentState = state.value ?? [];
    int maxOrderIndex = 0;
    if (currentState.isNotEmpty) {
      maxOrderIndex = currentState.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b);
    }

    final task = TaskModel()
      ..title = title
      ..description = description
      ..dueDate = dueDate
      ..createdAt = DateTime.now()
      ..isCompleted = false
      ..orderIndex = maxOrderIndex + 1;

    if (category != null) {
      task.category.value = category;
    }

    await isar.writeTxn(() async {
      await isar.taskModels.put(task);
      if (category != null) {
        await task.category.save();
      }
    });

    // Cài đặt nhắc nhở nếu có Due Date
    if (dueDate != null) {
      // Đặt lịch trước 1 tiếng, hoặc dùng luôn giờ do user chọn
      final scheduleTime = dueDate.subtract(const Duration(hours: 1));
      if (scheduleTime.isAfter(DateTime.now())) {
        await NotificationService().scheduleNotification(
          id: task.id,
          title: 'Nhắc nhở: ${task.title}',
          body: 'Công việc sắp đến hạn vào ${task.dueDate}',
          scheduledDate: scheduleTime,
        );
      }
    }
  }

  Future<void> updateTask(int taskId, String title, {String? description, DateTime? dueDate, CategoryModel? category}) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      final task = await isar.taskModels.get(taskId);
      if (task != null) {
        task.title = title;
        task.description = description;
        task.dueDate = dueDate;

        if (category != null) {
          task.category.value = category;
        } else {
          task.category.value = null;
        }

        await isar.taskModels.put(task);
        await task.category.save();

        if (dueDate != null && !task.isCompleted) {
          final scheduleTime = dueDate.subtract(const Duration(hours: 1));
          if (scheduleTime.isAfter(DateTime.now())) {
            await NotificationService().scheduleNotification(
              id: task.id,
              title: 'Nhắc nhở: ${task.title}',
              body: 'Công việc sắp đến hạn vào ${task.dueDate}',
              scheduledDate: scheduleTime,
            );
          }
        } else {
          await NotificationService().cancelNotification(taskId);
        }
      }
    });
  }

  Future<void> toggleTaskCompletion(int taskId) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      final task = await isar.taskModels.get(taskId);
      if (task != null) {
        task.isCompleted = !task.isCompleted;
        await isar.taskModels.put(task);

        if (task.isCompleted) {
          await NotificationService().cancelNotification(taskId);
        }
      }
    });
  }

  Future<void> deleteTask(int taskId) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.taskModels.delete(taskId);
    });
    await NotificationService().cancelNotification(taskId);
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null || currentState.isEmpty) return;

    final tasks = List<TaskModel>.from(currentState)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);

    for (int i = 0; i < tasks.length; i++) {
      tasks[i].orderIndex = i;
    }

    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.taskModels.putAll(tasks);
    });
  }
}

final taskListProvider = StreamNotifierProvider<TaskListNotifier, List<TaskModel>>(
  () => TaskListNotifier(),
);

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
final taskSortProvider = StateProvider<TaskSort>((ref) => TaskSort.custom);
final taskCategoryFilterProvider = StateProvider<CategoryModel?>((ref) => null);

// Thêm provider cho tính năng tìm kiếm
final taskSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredTaskListProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final taskListState = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);
  final sort = ref.watch(taskSortProvider);
  final categoryFilter = ref.watch(taskCategoryFilterProvider);
  final searchQuery = ref.watch(taskSearchQueryProvider).toLowerCase();

  return taskListState.whenData((tasks) {
    var filtered = tasks.where((task) {
      // 1. Lọc theo trạng thái hoàn thành
      if (filter == TaskFilter.completed && !task.isCompleted) return false;
      if (filter == TaskFilter.incomplete && task.isCompleted) return false;
      
      // 2. Lọc theo danh mục
      if (categoryFilter != null && task.category.value?.id != categoryFilter.id) return false;

      // 3. Lọc theo từ khóa tìm kiếm
      if (searchQuery.isNotEmpty) {
        final title = task.title.toLowerCase();
        final desc = task.description?.toLowerCase() ?? '';
        if (!title.contains(searchQuery) && !desc.contains(searchQuery)) return false;
      }

      return true;
    }).toList();

    if (sort == TaskSort.newest) {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sort == TaskSort.dueDate) {
      filtered.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else if (sort == TaskSort.custom) {
      filtered.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return filtered;
  });
});
