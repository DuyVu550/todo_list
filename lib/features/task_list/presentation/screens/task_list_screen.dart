import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/task_list_notifier.dart';
import '../providers/category_notifier.dart';
import '../../data/models/task_model.dart';
import '../../data/models/category_model.dart';
import 'category_list_screen.dart';
import 'dashboard_screen.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/services/backup_provider.dart';
import '../../data/models/sub_task_model.dart';

// Provider cục bộ để quản lý trạng thái mở/đóng thanh tìm kiếm
final isSearchingProvider = StateProvider.autoDispose<bool>((ref) => false);

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  void _showTaskDialog(BuildContext context, WidgetRef ref, {TaskModel? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    final subTaskController = TextEditingController();
    DateTime? selectedDate = task?.dueDate;
    CategoryModel? selectedCategory = task?.category.value;
    TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;
    List<SubTaskModel> currentSubTasks = task?.subTasks.map((e) => SubTaskModel()..title = e.title..isCompleted = e.isCompleted).toList() ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {

            return AlertDialog(
              title: Text(
                task == null ? 'Thêm công việc' : 'Chỉnh sửa công việc',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên công việc',
                      ),
                      autofocus: true,
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'Chưa chọn hạn chót'
                                : 'Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDate!)}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              if (context.mounted) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
                                );
                                if (time != null) {
                                  setState(() {
                                    selectedDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            }
                          },
                          child: const Text('Chọn ngày giờ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Consumer(
                      builder: (context, ref, child) {
                        final categoriesAsync = ref.watch(categoryListProvider);
                        
                        return categoriesAsync.when(
                          data: (categories) {
                            if (categories.isEmpty) return const SizedBox.shrink();
                            return DropdownButtonFormField<CategoryModel>(
                              decoration: const InputDecoration(
                                labelText: 'Danh mục',
                              ),
                              initialValue: selectedCategory,
                              items: [
                                const DropdownMenuItem<CategoryModel>(
                                  value: null,
                                  child: Text('Không có danh mục'),
                                ),
                                ...categories.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Color(c.colorValue),
                                          radius: 8,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.name.isEmpty ? '(Không tên)' : c.name,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) =>
                                  setState(() => selectedCategory = val),
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (_, __) => const Text('Lỗi tải danh mục'),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TaskPriority>(
                      decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
                      initialValue: selectedPriority,
                      items: const [
                        DropdownMenuItem(value: TaskPriority.low, child: Text('Thấp')),
                        DropdownMenuItem(value: TaskPriority.medium, child: Text('Trung bình')),
                        DropdownMenuItem(value: TaskPriority.high, child: Text('Cao')),
                        DropdownMenuItem(value: TaskPriority.urgent, child: Text('Khẩn cấp')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedPriority = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    const Align(alignment: Alignment.centerLeft, child: Text('Việc con (Sub-tasks):', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...currentSubTasks.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final st = entry.value;
                      return Row(
                        children: [
                          Checkbox(
                            value: st.isCompleted,
                            onChanged: (val) {
                              setState(() => st.isCompleted = val ?? false);
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: st.title),
                              onChanged: (val) => st.title = val,
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() => currentSubTasks.removeAt(idx));
                            },
                          ),
                        ],
                      );
                    }),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subTaskController,
                            decoration: const InputDecoration(hintText: 'Thêm việc con...'),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                setState(() {
                                  currentSubTasks.add(SubTaskModel()..title = val.trim());
                                  subTaskController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (subTaskController.text.trim().isNotEmpty) {
                              setState(() {
                                currentSubTasks.add(SubTaskModel()..title = subTaskController.text.trim());
                                subTaskController.clear();
                              });
                            }
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    if (task == null) {
                      ref
                          .read(taskListProvider.notifier)
                          .addTask(
                            title,
                            description: descController.text.trim(),
                            dueDate: selectedDate,
                            category: selectedCategory,
                            priority: selectedPriority,
                            subTasks: currentSubTasks,
                          );
                    } else {
                      ref
                          .read(taskListProvider.notifier)
                          .updateTask(
                            task.id,
                            title,
                            description: descController.text.trim(),
                            dueDate: selectedDate,
                            category: selectedCategory,
                            priority: selectedPriority,
                            subTasks: currentSubTasks,
                          );
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListAsync = ref.watch(filteredTaskListProvider);
    final isSearching = ref.watch(isSearchingProvider);

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm công việc...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(taskSearchQueryProvider.notifier).state = val;
                },
              )
            : Consumer(
                builder: (context, ref, child) {
                  final categoryFilter = ref.watch(taskCategoryFilterProvider);
                  if (categoryFilter != null) {
                    return Text('Todo List - ${categoryFilter.name}');
                  }
                  return const Text('Todo List');
                },
              ),
        actions: [
          if (isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Đóng tìm kiếm',
              onPressed: () {
                ref.read(isSearchingProvider.notifier).state = false;
                ref.read(taskSearchQueryProvider.notifier).state = '';
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Tìm kiếm',
              onPressed: () {
                ref.read(isSearchingProvider.notifier).state = true;
              },
            ),
          if (!isSearching)
            Consumer(
              builder: (context, ref, child) {
                final categoryFilter = ref.watch(taskCategoryFilterProvider);
                if (categoryFilter != null) {
                  return IconButton(
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Bỏ lọc Danh mục',
                    onPressed: () {
                      ref.read(taskCategoryFilterProvider.notifier).state = null;
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Quản lý Danh mục',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryListScreen()),
              );
            },
          ),
          PopupMenuButton<TaskFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc trạng thái',
            onSelected: (filter) =>
                ref.read(taskFilterProvider.notifier).state = filter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: TaskFilter.all, child: Text('Tất cả')),
              const PopupMenuItem(
                value: TaskFilter.completed,
                child: Text('Đã hoàn thành'),
              ),
              const PopupMenuItem(
                value: TaskFilter.incomplete,
                child: Text('Chưa hoàn thành'),
              ),
            ],
          ),
          PopupMenuButton<TaskSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onSelected: (sort) =>
                ref.read(taskSortProvider.notifier).state = sort,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TaskSort.custom,
                child: Text('Tùy chỉnh'),
              ),
              const PopupMenuItem(
                value: TaskSort.newest,
                child: Text('Mới nhất'),
              ),
              const PopupMenuItem(
                value: TaskSort.dueDate,
                child: Text('Hạn chót'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Hành động khác',
            onSelected: (value) {
              if (value == 'clear_completed') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xóa việc đã xong'),
                    content: const Text('Bạn có chắc chắn muốn xóa tất cả công việc đã hoàn thành?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(taskListProvider.notifier).clearCompletedTasks();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Text('Xóa tất cả việc đã xong'),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Tất cả Công việc'),
              onTap: () {
                ref.read(taskCategoryFilterProvider.notifier).state = null;
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Thống kê'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Quản lý Danh mục'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryListScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Sao lưu (Export JSON)'),
              onTap: () async {
                Navigator.pop(context);
                final path = await ref.read(backupServiceProvider).exportData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã lưu tại: $path')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Khôi phục (Import JSON)'),
              onTap: () async {
                Navigator.pop(context);
                final success = await ref.read(backupServiceProvider).importData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Khôi phục thành công' : 'Lỗi/Không tìm thấy file')));
                }
              },
            ),
            const Divider(),
            Consumer(
              builder: (context, ref, child) {
                final themeMode = ref.watch(themeProvider);
                final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
                return SwitchListTile(
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Chế độ Tối'),
                  value: isDark,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                );
              },
            ),

          ],
        ),
      ),
      body: taskListAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.withAlpha(128)),
                  const SizedBox(height: 16),
                  const Text('Chưa có công việc nào.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Hãy nhấn nút + để thêm mới.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          final filter = ref.watch(taskFilterProvider);
          final sort = ref.watch(taskSortProvider);
          final searchQuery = ref.watch(taskSearchQueryProvider);
          final categoryFilter = ref.watch(taskCategoryFilterProvider);

          final canReorder = filter == TaskFilter.all &&
                             sort == TaskSort.custom &&
                             searchQuery.isEmpty &&
                             categoryFilter == null;

          Widget buildTile(TaskModel task) {
            final category = task.category.value;
            return Dismissible(
              key: ValueKey('dismiss_${task.id}'),
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text('Bạn có chắc chắn muốn xóa công việc này?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                } else {
                  ref.read(taskListProvider.notifier).toggleTaskCompletion(task.id);
                  return false;
                }
              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  ref.read(taskListProvider.notifier).deleteTask(task.id);
                }
              },
              child: ListTile(
              key: ValueKey(task.id),
              onTap: () => _showTaskDialog(context, ref, task: task),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null &&
                      task.description!.isNotEmpty)
                    Text(task.description!),
                  if (task.dueDate != null)
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final dueDate = task.dueDate!;
                        final isOverdue = dueDate.isBefore(now) && !task.isCompleted;
                        final isToday = dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day;
                        final color = isOverdue ? Colors.red : (isToday ? Colors.orange : Colors.grey);
                        return Text(
                          'Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(dueDate)}',
                          style: TextStyle(color: color, fontSize: 12),
                        );
                      }
                    ),
                  if (category != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(category.colorValue).withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(category.colorValue)),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: Color(category.colorValue),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (task.priority != TaskPriority.medium)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.priority == TaskPriority.urgent ? Colors.red.withAlpha(51) : 
                               (task.priority == TaskPriority.high ? Colors.orange.withAlpha(51) : Colors.green.withAlpha(51)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: task.priority == TaskPriority.urgent ? Colors.red : 
                                 (task.priority == TaskPriority.high ? Colors.orange : Colors.green),
                        ),
                      ),
                      child: Text(
                        task.priority == TaskPriority.urgent ? 'Khẩn cấp' : 
                        (task.priority == TaskPriority.high ? 'Cao' : 'Thấp'),
                        style: TextStyle(
                          color: task.priority == TaskPriority.urgent ? Colors.red : 
                                 (task.priority == TaskPriority.high ? Colors.orange : Colors.green),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (task.subTasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Việc con: ${task.subTasks.where((e) => e.isCompleted).length}/${task.subTasks.length}',
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                    ),
                ],
              ),
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(taskListProvider.notifier)
                        .toggleTaskCompletion(task.id);
                  }
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Xóa công việc',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text('Bạn có chắc chắn muốn xóa công việc này?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(taskListProvider.notifier).deleteTask(task.id);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }

        if (canReorder) {
            return ReorderableListView.builder(
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(taskListProvider.notifier).reorderTasks(oldIndex, newIndex);
              },
              itemBuilder: (context, index) => buildTile(tasks[index]),
            );
          } else {
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => buildTile(tasks[index]),
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context, ref),
        tooltip: 'Thêm công việc mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}
