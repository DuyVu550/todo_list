import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/isar_provider.dart';
import 'backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final isar = ref.watch(isarProvider);
  return BackupService(isar);
});
