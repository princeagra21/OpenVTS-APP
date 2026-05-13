import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/database/app_database.dart';

/// Single app-wide Drift database provider.
///
/// The provider is intentionally app-scoped. Feature repositories receive
/// local sources instead of opening their own databases.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
