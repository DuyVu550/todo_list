import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_notifier.dart';
import '../providers/task_list_notifier.dart';
import '../../data/models/category_model.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    int selectedColor = category?.colorValue ?? Colors.blue.toARGB32();

    final List<Color> colorOptions = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.indigo, Colors.pink
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                category == null ? 'Thêm Danh mục' : 'Sửa Danh mục',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên danh mục',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  const Text('Chọn màu sắc:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colorOptions.map((color) {
                      final isSelected = selectedColor == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color.toARGB32()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withAlpha(isSelected ? 255 : 150),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black54 : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(color: color.withAlpha(100), blurRadius: 8, spreadRadius: 2)
                            ] : [],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    if (category == null) {
                      ref.read(categoryListProvider.notifier).addCategory(name, colorValue: selectedColor);
                    } else {
                      ref.read(categoryListProvider.notifier).updateCategory(category.id, name, colorValue: selectedColor);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Danh mục', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 80, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có danh mục nào.',
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: Color(category.colorValue),
                    radius: 16,
                  ),
                  title: Text(
                    category.name.isEmpty ? '(Không tên)' : category.name, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                  ),
                  onTap: () {
                    // Cập nhật State lọc theo Category và trở về màn hình chính
                    ref.read(taskCategoryFilterProvider.notifier).state = category;
                    Navigator.pop(context);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                        tooltip: 'Sửa danh mục',
                        onPressed: () => _showCategoryDialog(context, ref, category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: 'Xóa danh mục',
                        onPressed: () {
                          ref.read(categoryListProvider.notifier).deleteCategory(category.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
    );
  }
}
