import 'package:drift/drift.dart';

/// Vehicle list cache rows scoped by tenant/user/environment cache key.
///
/// This table stores only non-sensitive vehicle list data. Auth tokens and
/// session secrets must never be written to Drift/Hive.
class CachedVehicles extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get vehicleId => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get plateNumber => text().withDefault(const Constant(''))();
  TextColumn get imei => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant(''))();
  TextColumn get rawJson => text().withDefault(const Constant('{}'))();
  IntColumn get page => integer().withDefault(const Constant(1))();
  IntColumn get limit => integer().withDefault(const Constant(20))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get cachedAtMillis => integer()();
  IntColumn get staleAtMillis => integer()();
  IntColumn get expiresAtMillis => integer()();

  @override
  Set<Column> get primaryKey => {cacheKey, vehicleId};
}
