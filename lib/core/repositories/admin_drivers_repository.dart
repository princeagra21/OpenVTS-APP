import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_driver_details.dart';
import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminDriversRepository {
  final ApiClient api;

  const AdminDriversRepository({required this.api});

  Future<Result<List<AdminDriverListItem>>> getDrivers({
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
      '/admin/drivers',
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(data);
        final out = list
            .whereType<Map>()
            .map(
              (item) => AdminDriverListItem.fromRaw(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            )
            .toList();
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminDriverDetails>> getDriverDetails(
    String driverId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/admin/drivers/$driverId',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        return Result.ok(AdminDriverDetails.fromRaw(map));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateDriverStatus(
    String driverId,
    bool isActive, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      '/admin/drivers/$driverId',
      data: <String, dynamic>{
        // Postman sample uses lower-case isactive.
        'isactive': isActive,
        // Keep camelCase for backend variants.
        'isActive': isActive,
      },
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

    final nestedData = level0['data'];
    if (nestedData is Map) {
      final level1 = Map<String, dynamic>.from(nestedData.cast());

      final level2 = level1['data'];
      if (level2 is Map) {
        return Map<String, dynamic>.from(level2.cast());
      }

      final candidates = [level1['driver'], level1['item'], level1['result']];
      for (final candidate in candidates) {
        if (candidate is Map<String, dynamic>) return candidate;
        if (candidate is Map) {
          return Map<String, dynamic>.from(candidate.cast());
        }
      }

      return level1;
    }

    final candidates = [
      level0['driver'],
      level0['item'],
      level0['result'],
      level0['config'],
      level0['settings'],
    ];
    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) return Map<String, dynamic>.from(candidate.cast());
    }

    return level0;
  }

  List _extractList(Object? data) {
    List? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      final candidates = [
        map['driverslist'],
        map['driverlist'],
        map['drivers'],
        map['items'],
        map['result'],
        map['results'],
        map['data'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) return candidate;
        if (candidate is Map || candidate is List) {
          final found = walk(candidate, depth + 1);
          if (found != null) return found;
        }
      }

      for (final value in map.values) {
        if (value is Map || value is List) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }

      return null;
    }

    return walk(data, 0) ?? const [];
  }
}
