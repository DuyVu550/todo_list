import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Provider này sẽ cung cấp instance của Isar Database cho toàn bộ ứng dụng.
/// Sẽ được override ở ProviderScope trong main.dart
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden with a valid Isar instance in main.dart');
});
