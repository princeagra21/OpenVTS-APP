import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/user_vehicle_details.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserVehiclesRepository {
  final ApiClient api;

  const UserVehiclesRepository({required this.api});

  Future<Result<List<VehicleListItem>>> getVehicles({
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;

    final res = await api.get(
      '/user/vehicles',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['vehicles', 'items', 'rows'],
        );

        final out = <VehicleListItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(VehicleListItem(item));
            } else if (item is Map) {
              out.add(VehicleListItem(Map<String, dynamic>.from(item.cast())));
            }
          }
        }

        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> createVehicle(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/user/vehicles',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<UserVehicleDetails>> getVehicleDetails(
    String vehicleId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/vehicles/$vehicleId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) =>
          Result.ok(UserVehicleDetails.fromRaw(_extractMap(data))),
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
        final level2 = Map<String, dynamic>.from(level2Raw.cast());
        final nestedVehicle = level2['vehicle'];
        if (nestedVehicle is Map<String, dynamic>) return nestedVehicle;
        if (nestedVehicle is Map) {
          return Map<String, dynamic>.from(nestedVehicle.cast());
        }
        return level2;
      }

      final level1Vehicle = level1['vehicle'];
      if (level1Vehicle is Map<String, dynamic>) return level1Vehicle;
      if (level1Vehicle is Map) {
        return Map<String, dynamic>.from(level1Vehicle.cast());
      }

      return level1;
    }

    final level0Vehicle = level0['vehicle'];
    if (level0Vehicle is Map<String, dynamic>) return level0Vehicle;
    if (level0Vehicle is Map) {
      return Map<String, dynamic>.from(level0Vehicle.cast());
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
}
