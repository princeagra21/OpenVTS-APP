import 'package:hive_flutter/hive_flutter.dart';

/// Hive remains for small key-value cache. Drift-backed query-heavy cache
/// lives under `core/database` and must be used for vehicle/history data that
/// needs tenant-scoped querying.

abstract class HiveBoxes {
  static const String settings = 'settings_box';
  static const String vehicles = 'vehicles_cache_box';
  static const String drivers = 'drivers_cache_box';
  static const String alerts = 'alerts_box';
}

class CacheStorage {
  const CacheStorage(this.box);

  final Box<dynamic> box;

  T? read<T>(String key) {
    final value = box.get(key);
    return value is T ? value : null;
  }

  Future<void> write(String key, Object? value) => box.put(key, value);

  Future<void> remove(String key) => box.delete(key);
}

Future<void> initCacheStorage() async {
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<dynamic>(HiveBoxes.settings),
    Hive.openBox<dynamic>(HiveBoxes.vehicles),
    Hive.openBox<dynamic>(HiveBoxes.drivers),
    Hive.openBox<dynamic>(HiveBoxes.alerts),
  ]);
}
