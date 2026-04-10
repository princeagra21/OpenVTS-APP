import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/models/user_driver_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserDriversRepository {
  final ApiClient api;

  const UserDriversRepository({required this.api});

  Future<Result<List<AdminDriverListItem>>> getDrivers({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/user/drivers', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['drivers', 'items', 'rows'],
        );

        final out = <AdminDriverListItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminDriverListItem.fromRaw(item));
            } else if (item is Map) {
              out.add(
                AdminDriverListItem.fromRaw(
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

  Future<Result<AdminDriverListItem>> createDriver(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/user/drivers',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final map = _extractMap(data, extraKeys: const ['driver']);
        return Result.ok(AdminDriverListItem.fromRaw(map));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<UserDriverDetails>> getDriverDetails(
    String driverId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/drivers/$driverId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) =>
          Result.ok(UserDriverDetails.fromRaw(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> deleteDriver(
    String driverId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.delete(
      '/user/drivers/$driverId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateDriver(
    String driverId,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/user/drivers/$driverId',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
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

  Map<String, dynamic> _extractMap(
    Object? data, {
    List<String> extraKeys = const [],
  }) {
    if (data is! Map) return const <String, dynamic>{};
    final level0 = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data.cast());
    final objectKeys = <String>['driver', ...extraKeys];

    Map<String, dynamic>? fromNode(Map<String, dynamic> node) {
      for (final key in objectKeys) {
        final value = node[key];
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value.cast());
      }
      return null;
    }

    final directLevel0 = fromNode(level0);
    if (directLevel0 != null) return directLevel0;

    final level1Raw = level0['data'] ?? level0['result'] ?? level0['item'];
    if (level1Raw is Map) {
      final level1 = Map<String, dynamic>.from(level1Raw.cast());
      final directLevel1 = fromNode(level1);
      if (directLevel1 != null) return directLevel1;

      final level2Raw = level1['data'] ?? level1['result'] ?? level1['item'];
      if (level2Raw is Map) {
        final level2 = Map<String, dynamic>.from(level2Raw.cast());
        final directLevel2 = fromNode(level2);
        if (directLevel2 != null) return directLevel2;
        return level2;
      }

      return level1;
    }

    return level0;
  }
}
