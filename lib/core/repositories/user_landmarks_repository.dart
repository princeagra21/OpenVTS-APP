import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserLandmarksRepository {
  final ApiClient api;

  const UserLandmarksRepository({required this.api});

  Future<Result<List<Map<String, dynamic>>>> getGeofences({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/user/geofences', cancelToken: cancelToken);
    return _listResult(res, extraKeys: const ['geofences']);
  }

  Future<Result<List<Map<String, dynamic>>>> getRoutes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/user/routes', cancelToken: cancelToken);
    return _listResult(res, extraKeys: const ['routes']);
  }

  Future<Result<List<Map<String, dynamic>>>> getPois({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/user/pois', cancelToken: cancelToken);
    return _listResult(res, extraKeys: const ['pois']);
  }

  Future<Result<void>> createGeofence(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/user/geofences',
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> createRoute(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/user/routes',
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> createPoi(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/user/pois',
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Result<List<Map<String, dynamic>>> _listResult(
    Result<dynamic> res, {
    List<String> extraKeys = const <String>[],
  }) {
    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: extraKeys);
        final out = <Map<String, dynamic>>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(item);
            } else if (item is Map) {
              out.add(Map<String, dynamic>.from(item.cast()));
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
