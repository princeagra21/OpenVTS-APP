import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_vehicle_details.dart';
import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminVehiclesRepository {
  final ApiClient api;

  const AdminVehiclesRepository({required this.api});

  Future<Result<List<AdminVehicleListItem>>> getVehicles({
    String? search,
    String? status,
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }
    if (page != null) query['page'] = page;
    if (limit != null) query['limit'] = limit;

    final res = await api.get(
      '/admin/vehicles',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: const ['vehicles', 'rows']);
        final out = <AdminVehicleListItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminVehicleListItem.fromRaw(item));
            } else if (item is Map) {
              out.add(
                AdminVehicleListItem.fromRaw(
                  Map<String, dynamic>.from(item.cast()),
                ),
              );
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminVehicleDetails>> getVehicleDetails(
    String vehicleId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/vehicles/$vehicleId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) =>
          Result.ok(AdminVehicleDetails.fromRaw(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<MapVehiclePoint>>> getTelemetry({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/admin/map-telemetry', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['telemetry', 'points', 'vehicles', 'rows'],
        );
        final out = <MapVehiclePoint>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(MapVehiclePoint(item));
            } else if (item is Map) {
              out.add(MapVehiclePoint(Map<String, dynamic>.from(item.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<MapVehiclePoint>>> getVehicleTrailByImei(
    String imei, {
    int hours = 24,
    int? maxPoints,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{'hours': hours};
    if (maxPoints != null) query['maxPoints'] = maxPoints;

    final res = await api.get(
      '/admin/vehicles/by-imei/$imei/trail',
      queryParameters: query,
      cancelToken: cancelToken,
    );

    return _mapPointListResult(
      res,
      extraKeys: const ['points', 'trail', 'history'],
    );
  }

  Future<Result<List<MapVehiclePoint>>> getVehicleReplayByImei(
    String imei, {
    required DateTime from,
    required DateTime to,
    int? maxPoints,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    };
    if (maxPoints != null) query['maxPoints'] = maxPoints;

    final res = await api.get(
      '/admin/vehicles/by-imei/$imei/replay',
      queryParameters: query,
      cancelToken: cancelToken,
    );

    return _mapPointListResult(
      res,
      extraKeys: const ['points', 'trail', 'history'],
    );
  }

  Future<Result<List<MapVehiclePoint>>> getVehicleHistoryByImei(
    String imei, {
    required DateTime from,
    required DateTime to,
    int? maxPoints,
    int? stopMin,
    int? overspeedKph,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    };
    if (maxPoints != null) query['maxPoints'] = maxPoints;
    if (stopMin != null) query['stopMin'] = stopMin;
    if (overspeedKph != null) query['overspeedKph'] = overspeedKph;

    final res = await api.get(
      '/admin/vehicles/by-imei/$imei/history',
      queryParameters: query,
      cancelToken: cancelToken,
    );

    return _mapPointListResult(
      res,
      extraKeys: const ['points', 'trail', 'history'],
    );
  }

  Future<Result<void>> updateVehicleStatus(
    String vehicleId,
    bool isActive, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/vehicles/$vehicleId',
      data: <String, dynamic>{'isActive': isActive},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(Object? data) {
    if (data is! Map) return const <String, dynamic>{};

    final level0 = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data.cast());

    final level1Raw = level0['data'];
    if (level1Raw is Map) {
      final level1 = Map<String, dynamic>.from(level1Raw.cast());
      final level2Raw = level1['data'];
      if (level2Raw is Map) {
        return Map<String, dynamic>.from(level2Raw.cast());
      }

      final level1Candidates = [
        level1['item'],
        level1['vehicle'],
        level1['result'],
      ];
      for (final candidate in level1Candidates) {
        if (candidate is Map<String, dynamic>) return candidate;
        if (candidate is Map) {
          return Map<String, dynamic>.from(candidate.cast());
        }
      }

      return level1;
    }

    final level0Candidates = [
      level0['item'],
      level0['vehicle'],
      level0['result'],
      level0['settings'],
      level0['config'],
    ];
    for (final candidate in level0Candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) return Map<String, dynamic>.from(candidate.cast());
    }

    return level0;
  }

  List? _extractList(Object? data, {List<String> extraKeys = const []}) {
    if (data is List) return data;

    final keys = <String>['data', 'items', 'result', 'results', ...extraKeys];

    List? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      for (final key in keys) {
        final value = map[key];
        if (value is List) return value;
      }

      for (final value in map.values) {
        if (value is Map || value is List) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }

      return null;
    }

    return walk(data, 0);
  }

  Result<List<MapVehiclePoint>> _mapPointListResult(
    Result<dynamic> res, {
    List<String> extraKeys = const [],
  }) {
    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: <String>[
            'telemetry',
            'points',
            'vehicles',
            'rows',
            ...extraKeys,
          ],
        );
        final out = <MapVehiclePoint>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(MapVehiclePoint(item));
            } else if (item is Map) {
              out.add(MapVehiclePoint(Map<String, dynamic>.from(item.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }
}
