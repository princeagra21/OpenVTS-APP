import 'package:drift/drift.dart';

QueryExecutor createDatabaseConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError('Local database is not supported on this platform.');
  });
}
