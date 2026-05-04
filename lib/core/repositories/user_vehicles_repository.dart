import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/models/superadmin_document_type.dart';
import 'package:fleet_stack/core/models/user_vehicle_details.dart';
import 'package:fleet_stack/core/models/vehicle_document_item.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/models/vehicle_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

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

  Future<Result<List<VehicleDocumentItem>>> getVehicleDocuments(
    String vehicleId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/vehicles/$vehicleId/documents',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['documents', 'items', 'rows'],
        );
        final out = <VehicleDocumentItem>[];
        if (list != null) {
          for (final item in list.whereType<Map>()) {
            out.add(
              VehicleDocumentItem(
                item is Map<String, dynamic>
                    ? item
                    : Map<String, dynamic>.from(item.cast()),
              ),
            );
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SuperadminDocumentType>>> getVehicleDocumentTypes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/documenttypes/VEHICLE', cancelToken: cancelToken);
    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['documentTypes', 'types'],
        );
        final out = <SuperadminDocumentType>[];
        if (list != null) {
          for (final it in list.whereType<Map>()) {
            out.add(
              SuperadminDocumentType.fromJson(
                it is Map<String, dynamic>
                    ? it
                    : Map<String, dynamic>.from(it.cast()),
              ),
            );
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> uploadVehicleDocument({
    required String vehicleId,
    required String title,
    required int docTypeId,
    required Uint8List fileBytes,
    required String filename,
    bool isVisible = true,
    String? tags,
    String? expiryAt,
    String? contentType,
    CancelToken? cancelToken,
  }) async {
    final mediaType = (contentType == null || contentType.trim().isEmpty)
        ? null
        : MediaType.parse(contentType);
    final form = FormData.fromMap({
      'title': title,
      'docTypeId': docTypeId.toString(),
      'isVisible': isVisible,
      if (tags != null && tags.trim().isNotEmpty) 'tags': tags.trim(),
      if (expiryAt != null && expiryAt.trim().isNotEmpty) 'expiryAt': expiryAt,
      'File': MultipartFile.fromBytes(
        fileBytes,
        filename: filename,
        contentType: mediaType,
      ),
    });
    final res = await api.post(
      '/user/vehicles/$vehicleId/documents',
      data: form,
      cancelToken: cancelToken,
      options: Options(contentType: 'multipart/form-data'),
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

  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/user/map-telemetry', cancelToken: cancelToken);
    return _mapPointListResult(
      res,
      extraKeys: const ['telemetry', 'points', 'vehicles', 'rows'],
    );
  }

  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/vehicles/by-imei/$imei/details',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = _coerceMap(data);
        final payload = _extractMap(data);
        final nested = _coerceMap(payload['data']);
        final nestedFromRoot = _extractMapFromNested(payload);

        final vehicle = _coerceMap(
          payload['vehicle'] ??
              nested['vehicle'] ??
              nestedFromRoot['vehicle'] ??
              root['vehicle'],
        );
        final telemetry = _coerceMap(
          payload['telemetry'] ??
              nested['telemetry'] ??
              nestedFromRoot['telemetry'] ??
              root['telemetry'],
        );

        final mergedVehicle = vehicle.isNotEmpty
            ? vehicle
            : (nested.isNotEmpty
                  ? nested
                  : (nestedFromRoot.isNotEmpty
                      ? nestedFromRoot
                      : (payload.isNotEmpty ? payload : root)));

        return Result.ok(
          VehicleDetails({
            'data': {
              'vehicle': mergedVehicle,
              'telemetry': telemetry,
            },
          }),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<String>> reverseGeocode(
    double lat,
    double lng, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/geocoding/reverse',
      queryParameters: <String, dynamic>{
        'lat': lat,
        'lng': lng,
      },
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = _coerceMap(data);
        final level1 = _extractMap(data);
        final level2 = _extractMapFromNested(level1);
        final level3 = _extractMapFromNested(level2);

        final address = _firstNonEmpty([
          level3['address'],
          level2['address'],
          level1['address'],
          root['address'],
          level3['formattedAddress'],
          level2['formattedAddress'],
          level1['formattedAddress'],
          root['formattedAddress'],
          level3['display_name'],
          level2['display_name'],
          level1['display_name'],
          root['display_name'],
        ]);

        return Result.ok(address.isEmpty ? 'Address unavailable' : address);
      },
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

  Map<String, dynamic> _extractMapFromNested(Map<String, dynamic> data) {
    final candidates = [
      data['data'],
      data['item'],
      data['vehicle'],
      data['result'],
      data['details'],
    ];
    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) {
        return Map<String, dynamic>.from(candidate.cast());
      }
    }
    return data;
  }

  Map<String, dynamic> _coerceMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return const <String, dynamic>{};
  }

  String _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
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
