import 'package:isar/isar.dart';
import 'category_model.dart';
import 'sub_task_model.dart';

part 'task_model.g.dart';

enum TaskPriority { low, medium, high, urgent }

/// Lớp đại diện cho một Công việc (Task) trong Database.
/// Annotation @collection thông báo cho Isar biết đây là một bảng dữ liệu.
@collection
class TaskModel {
  /// ID duy nhất của công việc. Isar.autoIncrement giúp tự động tăng ID khi tạo mới.
  Id id = Isar.autoIncrement;

  /// Tên của công việc (bắt buộc phải có).
  late String title;

  /// Mô tả chi tiết công việc (không bắt buộc, có thể null).
  String? description;

  /// Danh sách việc con (Sub-tasks).
  List<SubTaskModel> subTasks = [];

  /// Trạng thái hoàn thành của công việc. Mặc định khi tạo mới là false (chưa hoàn thành).
  bool isCompleted = false;

  /// Thứ tự của công việc trong danh sách (dùng cho tính năng kéo thả).
  int orderIndex = 0;

  /// Mức độ ưu tiên của công việc.
  @enumerated
  TaskPriority priority = TaskPriority.medium;

  /// Thời gian tạo công việc (bắt buộc).
  late DateTime createdAt;

  /// Thời gian hạn chót của công việc (không bắt buộc, có thể null).
  DateTime? dueDate;

  /// Liên kết công việc với một Danh mục (Category) cụ thể.
  final category = IsarLink<CategoryModel>();
}
