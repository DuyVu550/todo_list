import 'package:isar/isar.dart';

part 'category_model.g.dart';

@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  late String name;

  /// Mã màu ARGB để hiển thị trên UI. Mặc định là màu xanh.
  int colorValue = 0xFF2196F3; // Colors.blue.value

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
