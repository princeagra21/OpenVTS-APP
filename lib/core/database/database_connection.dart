import 'package:drift/drift.dart';

import 'database_connection_stub.dart'
    if (dart.library.io) 'database_connection_io.dart'
    if (dart.library.html) 'database_connection_web.dart';

QueryExecutor openDatabaseConnection() => createDatabaseConnection();
