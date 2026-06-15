import 'package:isar/isar.dart';
import 'category_model.dart';

part 'task_model.g.dart';

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

  /// Trạng thái hoàn thành của công việc. Mặc định khi tạo mới là false (chưa hoàn thành).
  bool isCompleted = false;

  /// Thứ tự của công việc trong danh sách (dùng cho tính năng kéo thả).
  int orderIndex = 0;

  /// Thời gian tạo công việc (bắt buộc).
  late DateTime createdAt;

  /// Thời gian hạn chót của công việc (không bắt buộc, có thể null).
  DateTime? dueDate;

  /// Liên kết công việc với một Danh mục (Category) cụ thể.
  final category = IsarLink<CategoryModel>();
}
