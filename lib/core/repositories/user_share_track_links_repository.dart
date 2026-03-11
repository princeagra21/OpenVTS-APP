import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/user_share_track_link_item.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserShareTrackLinksRepository {
  final ApiClient api;

  const UserShareTrackLinksRepository({required this.api});

  Future<Result<List<UserShareTrackLinkItem>>> getLinks({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/sharetracklinks',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: const ['items']);
        final out = <UserShareTrackLinkItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(UserShareTrackLinkItem(item));
            } else if (item is Map) {
              out.add(
                UserShareTrackLinkItem(Map<String, dynamic>.from(item.cast())),
              );
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<VehicleListItem>>> getVehicles({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/vehicles',
      queryParameters: const {'limit': 100},
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final list = _extractList(data, extraKeys: const ['vehicles']);
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

  Future<Result<UserShareTrackLinkItem>> createLink({
    required List<String> vehicleIds,
    required String expiryAtIso,
    required bool isGeofence,
    required bool isHistory,
    CancelToken? cancelToken,
  }) async {
    final primaryPayload = <String, dynamic>{
      'vehicleIds': vehicleIds.map(_normalizeId).toList(),
      'expiryAt': expiryAtIso,
      'isGeofence': isGeofence,
      'isHistory': isHistory,
    };

    final primary = await api.post(
      '/user/sharetracklinks',
      data: primaryPayload,
      cancelToken: cancelToken,
    );

    if (primary.isSuccess) {
      return primary.when(
        success: (data) => Result.ok(
          UserShareTrackLinkItem(_extractMap(data, extraKeys: const ['data'])),
        ),
        failure: (err) => Result.fail(err),
      );
    }

    if (vehicleIds.length == 1) {
      final error = primary.error;
      if (error is ApiException && error.statusCode == 400) {
        final fallbackPayload = <String, dynamic>{
          'vehicleId': _normalizeId(vehicleIds.first),
          'expiresAt': expiryAtIso,
          'isGeofence': isGeofence,
          'isHistory': isHistory,
        };
        final fallback = await api.post(
          '/user/sharetracklinks',
          data: fallbackPayload,
          cancelToken: cancelToken,
        );
        return fallback.when(
          success: (data) => Result.ok(
            UserShareTrackLinkItem(
              _extractMap(data, extraKeys: const ['data']),
            ),
          ),
          failure: (err) => Result.fail(err),
        );
      }
    }

    return primary.when(
      success: (data) => Result.ok(
        UserShareTrackLinkItem(_extractMap(data, extraKeys: const ['data'])),
      ),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<UserShareTrackLinkItem>> setLinkActive(
    String id,
    bool isActive, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/user/sharetracklinks/$id',
      data: {'isActive': isActive},
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) => Result.ok(
        UserShareTrackLinkItem(_extractMap(data, extraKeys: const ['data'])),
      ),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> deleteLink(String id, {CancelToken? cancelToken}) async {
    final res = await api.delete(
      '/user/sharetracklinks/$id',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Object _normalizeId(String raw) => int.tryParse(raw) ?? raw;

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
