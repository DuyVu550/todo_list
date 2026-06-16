import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_list/features/task_list/data/models/task_model.dart';
import 'package:todo_list/features/task_list/data/models/sub_task_model.dart';
import 'package:todo_list/features/task_list/presentation/providers/task_list_notifier.dart';
import 'package:todo_list/features/task_list/presentation/screens/task_list_screen.dart';

import 'package:todo_list/features/task_list/data/models/category_model.dart';

// Tạo một Mock Notifier để test giao diện độc lập với Database
class MockTaskListNotifier extends StreamNotifier<List<TaskModel>> implements TaskListNotifier {
  List<TaskModel> _tasks = [];

  @override
  Stream<List<TaskModel>> build() async* {
    yield _tasks;
  }

  @override
  Future<void> addTask(String title, {String? description, DateTime? dueDate, CategoryModel? category, TaskPriority priority = TaskPriority.medium, List<SubTaskModel> subTasks = const []}) async {
    final task = TaskModel()
      ..id = DateTime.now().millisecondsSinceEpoch
      ..title = title
      ..description = description
      ..createdAt = DateTime.now()
      ..isCompleted = false
      ..orderIndex = _tasks.length;
    if (category != null) {
      task.category.value = category;
    }
    _tasks = [..._tasks, task];
    state = AsyncData(_tasks);
  }

  @override
  Future<void> updateTask(int taskId, String title, {String? description, DateTime? dueDate, CategoryModel? category, TaskPriority priority = TaskPriority.medium, List<SubTaskModel> subTasks = const []}) async {
    _tasks = _tasks.map((t) {
      if (t.id == taskId) {
        t.title = title;
        t.description = description;
        t.dueDate = dueDate;
        if (category != null) {
          t.category.value = category;
        } else {
          t.category.value = null;
        }
      }
      return t;
    }).toList();
    state = AsyncData(_tasks);
  }

  @override
  Future<void> toggleSubTaskCompletion(int taskId, int subTaskIndex) async {
    final task = state.value!.firstWhere((t) => t.id == taskId);
    if (subTaskIndex >= 0 && subTaskIndex < task.subTasks.length) {
      task.subTasks[subTaskIndex].isCompleted = !task.subTasks[subTaskIndex].isCompleted;
      state = AsyncValue.data(List.from(state.value!));
    }
  }

  @override
  Future<void> toggleTaskCompletion(int taskId) async {
    final task = state.value!.firstWhere((t) => t.id == taskId);
    task.isCompleted = !task.isCompleted;
    state = AsyncValue.data(List.from(state.value!));
  }

  @override
  Future<void> deleteTask(int taskId) async {
    _tasks = _tasks.where((t) => t.id != taskId).toList();
    state = AsyncData(_tasks);
  }

  @override
  Future<void> clearCompletedTasks() async {
    _tasks = _tasks.where((t) => !t.isCompleted).toList();
    state = AsyncData(_tasks);
  }

  @override
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final tasks = List<TaskModel>.from(_tasks)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);
    for (int i = 0; i < tasks.length; i++) {
      tasks[i].orderIndex = i;
    }
    _tasks = tasks;
    state = AsyncData(_tasks);
  }
}

void main() {
  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        taskListProvider.overrideWith(() => MockTaskListNotifier()),
      ],
      child: const MaterialApp(
        home: TaskListScreen(),
      ),
    );
  }

  testWidgets('Should display empty message when no tasks', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    expect(find.text('Chưa có công việc nào.'), findsOneWidget);
  });

  testWidgets('Should add task when FAB is tapped and form is filled', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Điền tên công việc và mô tả vào Dialog
    await tester.enterText(find.byType(TextField).at(0), 'Task Title');
    await tester.enterText(find.byType(TextField).at(1), 'Task Desc');

    // Lưu
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Task Title'), findsOneWidget);
    expect(find.text('Task Desc'), findsOneWidget);
  });

  testWidgets('Should edit task when edit icon is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Thêm một task mẫu trước
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Original Task');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Original Task'), findsOneWidget);

    // Tap vào ListTile để Edit
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Đổi tên
    await tester.enterText(find.byType(TextField).at(0), 'Updated Task');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Original Task'), findsNothing);
    expect(find.text('Updated Task'), findsOneWidget);
  });

  testWidgets('Should toggle checkbox and change style', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Thêm task
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Task 1');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    final checkbox = find.byType(Checkbox);
    expect(tester.widget<Checkbox>(checkbox).value, false);

    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(checkbox).value, true);
    final textWidget = tester.widget<Text>(find.text('Task 1'));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });

    testWidgets('Should edit task when tapped on ListTile', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredTaskListProvider.overrideWithValue(
              AsyncValue.data([
                TaskModel()..id = 1..title = 'Cũ'..isCompleted = false..orderIndex = 0
              ])
            )
          ],
          child: const MaterialApp(home: TaskListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the ListTile directly to edit
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Chỉnh sửa công việc'), findsOneWidget);
    });

  testWidgets('Should delete task when delete icon is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Thêm task
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Task 1');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Xác nhận xóa trong Dialog
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Chưa có công việc nào.'), findsOneWidget);
  });

  testWidgets('Should not add task if title is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Mở popup thêm mới
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Bỏ trống tiêu đề và nhấn Lưu
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    // Dialog vẫn còn hiện vì tiêu đề rỗng (return sớm trong logic)
    expect(find.text('Thêm công việc'), findsOneWidget);
    
    // Đóng dialog bằng nút Hủy để về màn hình chính
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    // Không có task nào được thêm
    expect(find.text('Chưa có công việc nào.'), findsOneWidget);
  });

  testWidgets('Should dismiss dialog without saving when Cancel is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Mở popup thêm mới
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Nhập dữ liệu nhưng nhấn Hủy
    await tester.enterText(find.byType(TextField).at(0), 'Task Canceled');
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    // Dialog biến mất và dữ liệu không được lưu
    expect(find.text('Thêm công việc'), findsNothing);
    expect(find.text('Task Canceled'), findsNothing);
    expect(find.text('Chưa có công việc nào.'), findsOneWidget);
  });

  testWidgets('Should filter tasks via AppBar menu', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Thêm Task 1
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Task 1');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    // Thêm Task 2
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Task 2');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    // Check Task 1 (Bất kể đang xếp ở đâu)
    final task1Tile = find.widgetWithText(ListTile, 'Task 1');
    final checkbox1 = find.descendant(of: task1Tile, matching: find.byType(Checkbox));
    await tester.tap(checkbox1);
    await tester.pumpAndSettle();

    // Mở menu Lọc và chọn "Đã hoàn thành"
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã hoàn thành').last);
    await tester.pumpAndSettle();

    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsNothing);

    // Mở menu Lọc và chọn "Chưa hoàn thành"
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chưa hoàn thành').last);
    await tester.pumpAndSettle();

    expect(find.text('Task 1'), findsNothing);
    expect(find.text('Task 2'), findsOneWidget);

    // Mở menu Sắp xếp để đảm bảo nút tồn tại và click không lỗi
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hạn chót').last);
    await tester.pumpAndSettle();
  });

  testWidgets('Should support drag-and-drop to reorder tasks in custom sort mode', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Thêm Task 1
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Task 1');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    // Thêm Task 2
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Task 2');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    // Check ban đầu: Task 1 ở trên, Task 2 ở dưới
    expect(find.byType(ReorderableListView), findsOneWidget);
    
    // Tìm Widget ListTile của các Task
    final task1Finder = find.widgetWithText(ListTile, 'Task 1');
    final task2Finder = find.widgetWithText(ListTile, 'Task 2');

    expect(task1Finder, findsOneWidget);
    expect(task2Finder, findsOneWidget);

    // Kéo thả Task 1 xuống dưới vị trí của Task 2
    // Trong môi trường test mặc định (Android), ReorderableListView sử dụng ReorderableDelayedDragStartListener
    final dragHandleFinder = find.byType(ReorderableDelayedDragStartListener).first;
    expect(dragHandleFinder, findsOneWidget);

    // Kéo tay cầm của Task 1 xuống dưới (ví dụ 100 pixel) để vượt qua vị trí của Task 2
    final firstLocation = tester.getCenter(task1Finder);
    final TestGesture gesture = await tester.startGesture(firstLocation);
    await tester.pump(const Duration(seconds: 1)); // Pump thời gian long press để kích hoạt drag
    await gesture.moveTo(firstLocation + const Offset(0.0, 150.0));
    await gesture.up();
    await tester.pumpAndSettle();

    // Sau khi kéo thả, verify thứ tự mới: Task 2 lên trước, Task 1 ra sau
    final listTileFinder = find.byType(ListTile);
    expect(tester.widget<Text>(find.descendant(of: listTileFinder.at(0), matching: find.byType(Text)).first).data, 'Task 2');
    expect(tester.widget<Text>(find.descendant(of: listTileFinder.at(1), matching: find.byType(Text)).first).data, 'Task 1');
  });

  testWidgets('Should have tooltips on action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Kiểm tra tooltip trên AppBar
    expect(find.byTooltip('Tìm kiếm'), findsOneWidget);
    expect(find.byTooltip('Quản lý Danh mục'), findsOneWidget);
    expect(find.byTooltip('Lọc trạng thái'), findsOneWidget);
    expect(find.byTooltip('Sắp xếp'), findsOneWidget);
    
    // Kiểm tra tooltip trên FloatingActionButton
    expect(find.byTooltip('Thêm công việc mới'), findsOneWidget);

    // Thêm một task để có nút xóa
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Task 1');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    // Kiểm tra tooltip trên nút xóa
    expect(find.byTooltip('Xóa công việc'), findsOneWidget);
  });
}
