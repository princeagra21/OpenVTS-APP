import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_quick_device.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_type.dart';
import 'package:open_vts/features/admin/domain/entities/pricing_plan.dart';
import 'package:open_vts/core/api/api_envelope.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';

class AdminVehiclesRepository {
  final LegacyApiTransport api;

  const AdminVehiclesRepository({required this.api});

  Future<Result<List<VehicleType>>> getVehicleTypes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      PublicApiPaths.vehicleTypes,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['types', 'items', 'data'],
        );
        final out = <VehicleType>[];
        for (final item in list) {
          out.add(VehicleType.fromRaw(item));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<DeviceType>>> getDeviceTypes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      PublicApiPaths.deviceTypes,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['types', 'items', 'data'],
        );
        final out = <DeviceType>[];
        for (final item in list) {
          out.add(DeviceType.fromRaw(item));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminQuickDevice>>> getQuickDevices({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.quickDevice,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['devices', 'items', 'data'],
        );
        final out = <AdminQuickDevice>[];
        for (final item in list) {
          out.add(AdminQuickDevice.fromRaw(item));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<PricingPlan>>> getPricingPlans({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.pricingPlans,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['plans', 'items', 'data'],
        );
        final out = <PricingPlan>[];
        for (final item in list) {
          out.add(PricingPlan(item));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AdminVehicleListItem>> createVehicle({
    required String name,
    required String vin,
    required String plateNumber,
    required String deviceId,
    required String vehicleTypeId,
    required String primaryUserId,
    required String planId,
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'vin': vin.trim(),
      'plateNumber': plateNumber.trim(),
      'deviceId': deviceId.trim(),
      'vehicleTypeId': vehicleTypeId.trim(),
      'primaryUserId': primaryUserId.trim(),
      'planId': planId.trim(),
    };

    final res = await api.post(
      AdminApiPaths.vehicles,
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) =>
          Result.ok(AdminVehicleListItem.fromRaw(_extractPayloadMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

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
      AdminApiPaths.vehicles,
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['vehicles', 'rows'],
        );
        final out = <AdminVehicleListItem>[];
        for (final item in list) {
          out.add(AdminVehicleListItem.fromRaw(item));
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
      AdminApiPaths.vehicleDetails(vehicleId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) =>
          Result.ok(AdminVehicleDetails.fromRaw(_extractPayloadMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<AdminUserListItem>>> getLinkedUsers(
    String vehicleId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.linkUsers(vehicleId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['users', 'rows', 'items', 'data'],
        );
        final out = <AdminUserListItem>[];
        for (final item in list) {
          out.add(AdminUserListItem.fromRaw(item));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<MapVehiclePoint>>> getTelemetry({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.mapTelemetry,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['telemetry', 'points', 'vehicles', 'rows'],
        );
        final out = <MapVehiclePoint>[];
        for (final item in list) {
          out.add(MapVehiclePoint(item));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    CancelToken? cancelToken,
  }) {
    return getTelemetry(cancelToken: cancelToken);
  }

  Future<Result<VehicleDetails>> getVehicleDetailsByImei(
    String imei, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.vehicleByImeiDetails(imei),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = ApiEnvelope.asMap(data);
        final payload = _extractPayloadMap(
          data,
          mapKeys: const ['data', 'item', 'result', 'vehicle', 'payload'],
        );
        final nested = ApiEnvelope.nestedMap(
          payload,
          mapKeys: const ['data', 'item', 'result', 'vehicle', 'payload'],
          maxDepth: 6,
        );

        final vehicle = ApiEnvelope.asMap(
          payload['vehicle'] ??
              nested['vehicle'] ??
              root['vehicle'] ??
              (nested.isNotEmpty ? nested : payload),
        );
        final telemetry = ApiEnvelope.asMap(
          payload['telemetry'] ?? nested['telemetry'] ?? root['telemetry'],
        );

        final mergedVehicle = vehicle.isNotEmpty
            ? vehicle
            : (nested.isNotEmpty
                  ? nested
                  : (payload.isNotEmpty ? payload : root));

        return Result.ok(
          VehicleDetails({
            'data': {'vehicle': mergedVehicle, 'telemetry': telemetry},
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
      GeocodingApiPaths.reverse,
      queryParameters: <String, dynamic>{'lat': lat, 'lng': lng},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final root = ApiEnvelope.asMap(data);
        final payload = _extractPayloadMap(data);
        final nested = ApiEnvelope.nestedMap(payload, maxDepth: 6);

        final address = ApiEnvelope.firstNonEmpty([
          nested['address'],
          payload['address'],
          root['address'],
          nested['formattedAddress'],
          payload['formattedAddress'],
          root['formattedAddress'],
          nested['display_name'],
          payload['display_name'],
          root['display_name'],
        ]);

        return Result.ok(address.isEmpty ? 'Address unavailable' : address);
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
      AdminApiPaths.vehicleByImeiTrail(imei),
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
      AdminApiPaths.vehicleByImeiReplay(imei),
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
      AdminApiPaths.vehicleByImeiHistory(imei),
      queryParameters: query,
      cancelToken: cancelToken,
    );

    return _mapPointListResult(
      res,
      extraKeys: const ['points', 'trail', 'history'],
    );
  }

  Future<Result<VehicleConfig>> getVehicleConfig(
    String vehicleId, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.vehicleConfig(vehicleId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(VehicleConfig(_extractPayloadMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateVehicleConfig(
    String vehicleId,
    VehicleConfigUpdate payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      AdminApiPaths.vehicleConfig(vehicleId),
      data: payload.toJson(),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<Map<String, dynamic>>>> getVehicleLogsByImei(
    String imei, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      AdminApiPaths.vehicleByImeiLogs(imei),
      queryParameters: query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['items', 'logs', 'rows', 'data'],
        );
        return Result.ok(list);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updateVehicleStatus(
    String vehicleId,
    bool isActive, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.patch(
      AdminApiPaths.vehicleDetails(vehicleId),
      data: <String, dynamic>{'isActive': isActive},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractPayloadMap(
    Object? data, {
    List<String> mapKeys = const [
      'data',
      'result',
      'item',
      'payload',
      'response',
      'vehicle',
      'settings',
      'config',
    ],
  }) {
    return ApiEnvelope.payload(data, mapKeys: mapKeys);
  }

  List<Map<String, dynamic>> _extractMapList(
    Object? data, {
    List<String> extraKeys = const [],
  }) {
    return ApiEnvelope.mapList(
      data,
      listKeys: <String>['data', 'items', 'result', 'results', ...extraKeys],
      maxDepth: 6,
    );
  }

  Result<List<MapVehiclePoint>> _mapPointListResult(
    Result<dynamic> res, {
    List<String> extraKeys = const [],
  }) {
    return res.when(
      success: (data) {
        final list = _extractMapList(
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
        for (final item in list) {
          out.add(MapVehiclePoint(item));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }
}
