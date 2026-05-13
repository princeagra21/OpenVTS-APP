import 'package:drift/drift.dart';

/// Time-range telemetry/history cache foundation.
///
/// This is intentionally separate from live telemetry state. It is for
/// query-heavy date-range replay/history data and should be populated by a
/// later history migration slice.
class CachedHistoryPoints extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get vehicleId => text()();
  TextColumn get imei => text().withDefault(const Constant(''))();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get speedKph => real().nullable()();
  RealColumn get heading => real().nullable()();
  BoolColumn get ignition => boolean().nullable()();
  IntColumn get recordedAtMillis => integer()();
  TextColumn get rawJson => text().withDefault(const Constant('{}'))();
  IntColumn get cachedAtMillis => integer()();

  @override
  Set<Column> get primaryKey => {
        cacheKey,
        vehicleId,
        recordedAtMillis,
      };
}
