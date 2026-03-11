import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserMapRepository {
  final ApiClient api;

  const UserMapRepository({required this.api});

  Future<Result<List<MapVehiclePoint>>> getTelemetry({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/user/map-telemetry', cancelToken: cancelToken);
    return _mapPointListResult(
      res,
      extraKeys: const ['telemetry', 'points', 'vehicles', 'rows'],
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
      '/user/vehicles/by-imei/$imei/trail',
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
      '/user/vehicles/by-imei/$imei/replay',
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
      '/user/vehicles/by-imei/$imei/history',
      queryParameters: query,
      cancelToken: cancelToken,
    );

    return _mapPointListResult(
      res,
      extraKeys: const ['points', 'trail', 'history'],
    );
  }

  Result<List<MapVehiclePoint>> _mapPointListResult(
    Result<dynamic> res, {
    List<String> extraKeys = const <String>[],
  }) {
    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: extraKeys);
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
}
