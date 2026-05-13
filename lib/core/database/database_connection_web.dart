import 'package:drift/drift.dart';

/// Web builds must not import drift/native.dart or sqlite3 FFI packages.
/// Vehicle cache is disabled on web via [vehicleLocalSourceProvider], so this
/// executor should never be opened in browser runs.
QueryExecutor createDatabaseConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError('Drift native cache is disabled on Flutter web.');
  });
}
