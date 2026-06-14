import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_list/core/database/isar_provider.dart';
import 'package:todo_list/features/task_list/presentation/providers/task_list_notifier.dart';
import '../../../../test_utils.dart';

void main() {
  late Isar isar;
  late ProviderContainer container;

  setUp(() async {
    isar = await setupTestIsar();
    container = createContainer(
      overrides: [isarProvider.overrideWithValue(isar)],
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    container.dispose();
  });

  test('Initial state should be empty list', () async {
    // Kích hoạt provider
    final sub = container.listen(taskListProvider, (_, __) {});

    // Đợi async notifier load (watch phát ra event đầu tiên)
    final state = await container.read(taskListProvider.future);
    expect(state, isEmpty);
    sub.close();
  });

  test('addTask should add a task to database and state', () async {
    // Kích hoạt
    final sub = container.listen(taskListProvider, (_, __) {});
    final notifier = container.read(taskListProvider.notifier);

    await notifier.addTask('Test Task', description: 'Test Desc');

    // Chờ Isar bắn event stream
    await Future.delayed(const Duration(milliseconds: 100));
    final state = container.read(taskListProvider).value;

    expect(state, isNotNull);
    expect(state!.length, 1);
    expect(state.first.title, 'Test Task');
    expect(state.first.description, 'Test Desc');
    expect(state.first.isCompleted, false);
    sub.close();
  });

  test('toggleTaskCompletion should update isCompleted', () async {
    final sub = container.listen(taskListProvider, (_, __) {});
    final notifier = container.read(taskListProvider.notifier);

    await notifier.addTask('Task 1');
    await Future.delayed(const Duration(milliseconds: 100));

    var state = container.read(taskListProvider).value!;
    final task = state.first;
    expect(task.isCompleted, false);

    await notifier.toggleTaskCompletion(task.id);
    await Future.delayed(const Duration(milliseconds: 100));

    state = container.read(taskListProvider).value!;
    expect(state.first.isCompleted, true);
    sub.close();
  });

  test('deleteTask should remove task', () async {
    final sub = container.listen(taskListProvider, (_, __) {});
    final notifier = container.read(taskListProvider.notifier);

    await notifier.addTask('Task 1');
    await Future.delayed(const Duration(milliseconds: 100));

    var state = container.read(taskListProvider).value!;
    expect(state.length, 1);
    final taskId = state.first.id;

    await notifier.deleteTask(taskId);
    await Future.delayed(const Duration(milliseconds: 100));

    state = container.read(taskListProvider).value!;
    expect(state, isEmpty);
    sub.close();
  });

  test('updateTask should modify the task details', () async {
    final sub = container.listen(taskListProvider, (_, __) {});
    final notifier = container.read(taskListProvider.notifier);

    await notifier.addTask('Original Title', description: 'Original Desc');
    await Future.delayed(const Duration(milliseconds: 100));

    var state = container.read(taskListProvider).value!;
    final task = state.first;
    expect(task.title, 'Original Title');
    expect(task.description, 'Original Desc');

    await notifier.updateTask(task.id, 'Updated Title', description: 'Updated Desc');
    await Future.delayed(const Duration(milliseconds: 100));

    state = container.read(taskListProvider).value!;
    expect(state.first.title, 'Updated Title');
    expect(state.first.description, 'Updated Desc');
    sub.close();
  });

  test('filteredTaskListProvider should filter tasks correctly', () async {
    final subList = container.listen(taskListProvider, (_, __) {});
    final subFilter = container.listen(filteredTaskListProvider, (_, __) {});
    final notifier = container.read(taskListProvider.notifier);

    // Thêm 2 task
    await notifier.addTask('Task 1');
    await Future.delayed(const Duration(milliseconds: 50));
    await notifier.addTask('Task 2');
    await Future.delayed(const Duration(milliseconds: 100));

    // Đánh dấu Task 1 là hoàn thành
    final tasks = container.read(taskListProvider).value!;
    await notifier.toggleTaskCompletion(tasks[0].id);
    await Future.delayed(const Duration(milliseconds: 100));

    // Test: Lọc tất cả (mặc định)
    var filteredTasks = container.read(filteredTaskListProvider).value!;
    expect(filteredTasks.length, 2);

    // Test: Lọc đã hoàn thành
    container.read(taskFilterProvider.notifier).state = TaskFilter.completed;
    await Future.delayed(const Duration(milliseconds: 100));
    filteredTasks = container.read(filteredTaskListProvider).value!;
    expect(filteredTasks.length, 1);
    expect(filteredTasks.first.title, 'Task 1');

    // Test: Lọc chưa hoàn thành
    container.read(taskFilterProvider.notifier).state = TaskFilter.incomplete;
    await Future.delayed(const Duration(milliseconds: 100));
    filteredTasks = container.read(filteredTaskListProvider).value!;
    expect(filteredTasks.length, 1);
    expect(filteredTasks.first.title, 'Task 2');

    // Test: Lọc theo từ khóa tìm kiếm
    container.read(taskFilterProvider.notifier).state = TaskFilter.all;
    container.read(taskSearchQueryProvider.notifier).state = 'task 1';
    await Future.delayed(const Duration(milliseconds: 100));
    filteredTasks = container.read(filteredTaskListProvider).value!;
    expect(filteredTasks.length, 1);
    expect(filteredTasks.first.title, 'Task 1');

    container.read(taskSearchQueryProvider.notifier).state = '';
    await Future.delayed(const Duration(milliseconds: 100));
    filteredTasks = container.read(filteredTaskListProvider).value!;
    expect(filteredTasks.length, 2);

    subList.close();
    subFilter.close();
  });

  test('filteredTaskListProvider should sort tasks correctly', () async {
    final subList = container.listen(taskListProvider, (_, __) {});
    final subSort = container.listen(filteredTaskListProvider, (_, __) {});
    final notifier = container.read(taskListProvider.notifier);

    final futureDate = DateTime.now().add(const Duration(days: 2));
    final pastDate = DateTime.now().subtract(const Duration(days: 2));

    await notifier.addTask('Task A', dueDate: futureDate);
    await Future.delayed(const Duration(milliseconds: 50));
    await notifier.addTask('Task B', dueDate: pastDate);
    await Future.delayed(const Duration(milliseconds: 100));

    // Mặc định là Mới nhất (Task B tạo sau nên xếp trên Task A)
    var filteredTasks = container.read(filteredTaskListProvider).value!;
    expect(filteredTasks.length, 2);
    expect(filteredTasks[0].title, 'Task B');
    expect(filteredTasks[1].title, 'Task A');

    // Sắp xếp theo hạn chót (Task B có hạn quá khứ nên xếp trên Task A ở tương lai)
    container.read(taskSortProvider.notifier).state = TaskSort.dueDate;
    await Future.delayed(const Duration(milliseconds: 100));
    filteredTasks = container.read(filteredTaskListProvider).value!;
    expect(filteredTasks[0].title, 'Task B');
    expect(filteredTasks[1].title, 'Task A');

    subList.close();
    subSort.close();
  });
}
