import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:open_vts/core/database/app_database.dart';
import 'package:open_vts/core/storage/cache_keys.dart';
import 'package:open_vts/core/storage/cache_policy.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';
import 'package:open_vts/shared/models/paginated_response.dart';

class VehicleListCacheHit {
  const VehicleListCacheHit({
    required this.page,
    required this.isStale,
  });

  final PaginatedResponse<Vehicle> page;
  final bool isStale;
}

class VehicleLocalSource {
  const VehicleLocalSource({
    required AppDatabase database,
    required CacheScopeResolver scopeResolver,
    CachePolicy cachePolicy = CachePolicy.vehicleList,
  })  : _database = database,
        _scopeResolver = scopeResolver,
        _cachePolicy = cachePolicy;

  final AppDatabase _database;
  final CacheScopeResolver _scopeResolver;
  final CachePolicy _cachePolicy;

  Future<VehicleListCacheHit?> readVehicleList({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    bool allowExpired = false,
  }) async {
    final cacheKey = await _vehicleListCacheKey(
      page: page,
      limit: limit,
      search: search,
      status: status,
    );
    final rows = await (_database.select(_database.cachedVehicles)
          ..where((row) => row.cacheKey.equals(cacheKey))
          ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
        .get();

    if (rows.isEmpty) return null;

    final now = DateTime.now();
    final first = rows.first;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(first.expiresAtMillis);
    if (!allowExpired && !_cachePolicy.isUsable(now, expiresAt)) {
      return null;
    }

    final staleAt = DateTime.fromMillisecondsSinceEpoch(first.staleAtMillis);
    final vehicles = rows.map(_vehicleFromRow).toList(growable: false);
    return VehicleListCacheHit(
      page: PaginatedResponse<Vehicle>(
        data: vehicles,
        total: first.total,
        page: first.page,
        limit: first.limit,
        isFromCache: true,
      ),
      isStale: !_cachePolicy.isFresh(now, staleAt),
    );
  }

  Future<void> saveVehicleList({
    required PaginatedResponse<Vehicle> pageData,
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final cacheKey = await _vehicleListCacheKey(
      page: page,
      limit: limit,
      search: search,
      status: status,
    );
    final scope = await _scopeResolver.resolve();
    final now = DateTime.now();
    final staleAt = _cachePolicy.staleAt(now);
    final expiresAt = _cachePolicy.expiresAt(now);
    final queryHash = CacheScopeResolver.queryKey({
      'page': page,
      'limit': limit,
      'search': search ?? '',
      'status': status ?? '',
    });

    await _database.transaction(() async {
      await (_database.delete(_database.cachedVehicles)..where((row) => row.cacheKey.equals(cacheKey))).go();
      await (_database.delete(_database.cacheMetadataEntries)..where((row) => row.cacheKey.equals(cacheKey))).go();

      final companions = <CachedVehiclesCompanion>[];
      for (var i = 0; i < pageData.data.length; i++) {
        final vehicle = pageData.data[i];
        companions.add(
          CachedVehiclesCompanion(
            cacheKey: Value(cacheKey),
            vehicleId: Value(_stableVehicleId(vehicle, i)),
            name: Value(vehicle.name),
            plateNumber: Value(vehicle.plateNumber),
            imei: Value(vehicle.imei),
            status: Value(vehicle.status),
            rawJson: Value(jsonEncode(_jsonSafe(vehicle.raw))),
            page: Value(pageData.page),
            limit: Value(pageData.limit),
            total: Value(pageData.total),
            sortOrder: Value(i),
            cachedAtMillis: Value(now.millisecondsSinceEpoch),
            staleAtMillis: Value(staleAt.millisecondsSinceEpoch),
            expiresAtMillis: Value(expiresAt.millisecondsSinceEpoch),
          ),
        );
      }

      if (companions.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(
            _database.cachedVehicles,
            companions,
            mode: InsertMode.insertOrReplace,
          );
        });
      }

      await _database.into(_database.cacheMetadataEntries).insert(
            CacheMetadataEntriesCompanion(
              cacheKey: Value(cacheKey),
              featureKey: const Value(CacheFeatureKeys.vehicleList),
              role: Value(scope.role),
              accountId: Value(scope.accountId),
              userId: Value(scope.userId),
              environmentKey: Value(scope.environmentKey),
              queryHash: Value(queryHash),
              itemCount: Value(pageData.data.length),
              createdAtMillis: Value(now.millisecondsSinceEpoch),
              updatedAtMillis: Value(now.millisecondsSinceEpoch),
              staleAtMillis: Value(staleAt.millisecondsSinceEpoch),
              expiresAtMillis: Value(expiresAt.millisecondsSinceEpoch),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  Future<void> clearAllVehicleCache() async {
    await (_database.delete(_database.cachedVehicles)).go();
  }

  Future<String> _vehicleListCacheKey({
    required int page,
    required int limit,
    String? search,
    String? status,
  }) async {
    final scope = await _scopeResolver.resolve();
    final queryHash = CacheScopeResolver.queryKey({
      'page': page,
      'limit': limit,
      'search': search ?? '',
      'status': status ?? '',
    });
    return scope.keyBuilder.feature(CacheFeatureKeys.vehicleList, queryHash);
  }

  static Vehicle _vehicleFromRow(CachedVehicle row) {
    final raw = _decodeRaw(row.rawJson);
    return Vehicle(
      id: row.vehicleId,
      name: row.name,
      plateNumber: row.plateNumber,
      imei: row.imei,
      status: row.status,
      raw: raw,
    );
  }

  static String _stableVehicleId(Vehicle vehicle, int index) {
    final id = vehicle.id.trim();
    if (id.isNotEmpty) return id;
    final imei = vehicle.imei.trim();
    if (imei.isNotEmpty) return 'imei:$imei';
    final plate = vehicle.plateNumber.trim();
    if (plate.isNotEmpty) return 'plate:$plate';
    return 'row:$index';
  }

  static Map<String, Object?> _decodeRaw(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return <String, Object?>{for (final entry in decoded.entries) entry.key.toString(): entry.value};
    } catch (_) {
      return const <String, Object?>{};
    }
    return const <String, Object?>{};
  }

  static Map<String, Object?> _jsonSafe(Map<String, Object?> raw) {
    return raw.map((key, value) => MapEntry(key, _jsonSafeValue(value)));
  }

  static Object? _jsonSafeValue(Object? value) {
    if (value == null || value is num || value is bool || value is String) return value;
    if (value is DateTime) return value.toIso8601String();
    if (value is Iterable) return value.map(_jsonSafeValue).toList(growable: false);
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries) entry.key.toString(): _jsonSafeValue(entry.value),
      };
    }
    return value.toString();
  }
}
