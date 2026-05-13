import 'package:drift/drift.dart';
import 'package:open_vts/core/database/tables/cache_metadata_table.dart';
import 'package:open_vts/core/database/tables/cached_history_point_table.dart';
import 'package:open_vts/core/database/tables/cached_vehicle_table.dart';
import 'package:open_vts/core/database/database_connection.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CachedVehicles,
    CachedHistoryPoints,
    CacheMetadataEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  AppDatabase.forExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  Future<void> clearAllCachedData() async {
    await transaction(() async {
      await delete(cachedVehicles).go();
      await delete(cachedHistoryPoints).go();
      await delete(cacheMetadataEntries).go();
    });
  }

  Future<void> clearCacheKey(String cacheKey) async {
    await transaction(() async {
      await (delete(cachedVehicles)..where((row) => row.cacheKey.equals(cacheKey))).go();
      await (delete(cachedHistoryPoints)..where((row) => row.cacheKey.equals(cacheKey))).go();
      await (delete(cacheMetadataEntries)..where((row) => row.cacheKey.equals(cacheKey))).go();
    });
  }
}
