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

// Provider cục bộ để quản lý trạng thái mở/đóng thanh tìm kiếm
final isSearchingProvider = StateProvider.autoDispose<bool>((ref) => false);

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  void _showTaskDialog(BuildContext context, WidgetRef ref, {TaskModel? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    DateTime? selectedDate = task?.dueDate;
    CategoryModel? selectedCategory = task?.category.value;

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
                                : 'Hạn: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
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
                              setState(() => selectedDate = date);
                            }
                          },
                          child: const Text('Chọn ngày'),
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
                              value: selectedCategory,
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
              onPressed: () {
                ref.read(isSearchingProvider.notifier).state = false;
                ref.read(taskSearchQueryProvider.notifier).state = '';
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
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
            onSelected: (sort) =>
                ref.read(taskSortProvider.notifier).state = sort,
            itemBuilder: (context) => [
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
            return const Center(child: Text('Chưa có công việc nào.'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final category = task.category.value;
              return ListTile(
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
                      Text(
                        'Hạn: ${DateFormat('dd/MM/yyyy').format(task.dueDate!)}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
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
                  onPressed: () {
                    ref.read(taskListProvider.notifier).deleteTask(task.id);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
