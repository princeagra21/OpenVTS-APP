import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_vehicle_preview_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminVehicleRepository {
  final ApiClient api;

  const AdminVehicleRepository({required this.api});

  Future<Result<List<AdminVehiclePreviewItem>>> getVehiclePreviewList({
    int limit = 5,
    CancelToken? cancelToken,
  }) async {
    final qp = <String, dynamic>{};
    if (limit > 0) qp['limit'] = limit;

    final res = await api.get(
      '/admin/vehicles',
      queryParameters: qp.isEmpty ? null : qp,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['vehicles', 'vehicleslist', 'rows'],
        );
        final out = <AdminVehiclePreviewItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminVehiclePreviewItem(item));
            } else if (item is Map) {
              out.add(
                AdminVehiclePreviewItem(Map<String, dynamic>.from(item.cast())),
              );
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<Map<String, String>>> getVehicleLiveStatus({
    List<String>? vehicleIds,
    List<String>? imeis,
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/admin/map-telemetry', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['telemetry', 'vehicles', 'points', 'rows'],
        );

        final out = <String, String>{};
        if (list != null) {
          for (final item in list) {
            final map = item is Map<String, dynamic>
                ? item
                : (item is Map ? Map<String, dynamic>.from(item.cast()) : null);
            if (map == null) continue;

            final status = AdminVehiclePreviewItem.normalizeStatusLabel(
              _str(
                map['status'] ??
                    map['vehicleStatus'] ??
                    map['liveStatus'] ??
                    map['motion'] ??
                    map['state'] ??
                    map['ignition'],
              ),
            );
            if (status == '—') continue;

            final id = _str(
              map['vehicleId'] ??
                  map['id'] ??
                  map['vid'] ??
                  map['vehicle'] ??
                  (map['vehicle'] is Map
                      ? (map['vehicle'] as Map)['id']
                      : null),
            );
            final imei = _str(
              map['imei'] ?? map['deviceImei'] ?? map['imeiNumber'],
            );

            if (id.isNotEmpty) out[id] = status;
            if (imei.isNotEmpty) out[imei] = status;
          }
        }

        if (vehicleIds != null && vehicleIds.isNotEmpty) {
          final filtered = <String, String>{};
          for (final id in vehicleIds) {
            final v = out[id.trim()];
            if (v != null) filtered[id.trim()] = v;
          }
          if (imeis != null) {
            for (final im in imeis) {
              final key = im.trim();
              final v = out[key];
              if (v != null) filtered[key] = v;
            }
          }
          return Result.ok(filtered);
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
      if (depth > 5) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = _asMap(node);
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

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  String _str(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
