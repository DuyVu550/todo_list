import 'package:isar/isar.dart';

part 'sub_task_model.g.dart';

@embedded
class SubTaskModel {
  String? title;
  bool isCompleted = false;
}
