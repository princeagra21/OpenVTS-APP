import 'package:drift/drift.dart';

/// Per-scope metadata for cache observability and safe invalidation.
class CacheMetadataEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get featureKey => text()();
  TextColumn get role => text()();
  TextColumn get accountId => text()();
  TextColumn get userId => text()();
  TextColumn get environmentKey => text()();
  TextColumn get queryHash => text().withDefault(const Constant(''))();
  IntColumn get itemCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();
  IntColumn get staleAtMillis => integer()();
  IntColumn get expiresAtMillis => integer()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}
