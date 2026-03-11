import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/user_route_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserRoutesRepository {
  final ApiClient api;

  const UserRoutesRepository({required this.api});

  Future<Result<List<UserRouteItem>>> getRoutes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/user/routes', cancelToken: cancelToken);
    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: const ['routes']);
        final out = <UserRouteItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(UserRouteItem(item));
            } else if (item is Map) {
              out.add(UserRouteItem(Map<String, dynamic>.from(item.cast())));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<UserRouteItem>> getRouteDetails(
    String routeId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/routes/$routeId',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(
        UserRouteItem(_extractMap(data, extraKeys: const ['route'])),
      ),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<UserRouteItem>> createRoute(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/user/routes',
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(
        UserRouteItem(_extractMap(data, extraKeys: const ['route'])),
      ),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<UserRouteItem>> updateRoute(
    String routeId,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/user/routes/$routeId',
      data: payload,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(
        UserRouteItem(_extractMap(data, extraKeys: const ['route'])),
      ),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> deleteRoute(
    String routeId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.delete(
      '/user/routes/$routeId',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(
    Object? data, {
    List<String> extraKeys = const [],
  }) {
    if (data is! Map) return const <String, dynamic>{};
    final keys = <String>['data', 'result', 'item', ...extraKeys];

    Map<String, dynamic>? walk(Object? node, int depth) {
      if (depth > 6 || node is! Map) return null;
      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      for (final key in keys) {
        final value = map[key];
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value.cast());
      }

      for (final value in map.values) {
        if (value is Map) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }
      return map;
    }

    return walk(data, 0) ?? const <String, dynamic>{};
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
