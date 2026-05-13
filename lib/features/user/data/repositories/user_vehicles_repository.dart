import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_document_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_list_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_details.dart';
import 'package:open_vts/core/api/api_envelope.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/features/user/data/sources/user_typed_api_transport.dart';

class UserVehiclesRepository {
  final UserTypedApiTransport api;

  UserVehiclesRepository({required Object api}) : api = api is UserTypedApiTransport ? api : UserTypedApiTransport.fromDio((api as dynamic).dio as Dio);

  Future<Result<List<VehicleListItem>>> getVehicles({
    int? limit,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;

    final res = await api.get(
      UserApiPaths.vehicles,
      queryParameters: query.isEmpty ? null : query,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['vehicles', 'items', 'rows'],
        );

        final out = <VehicleListItem>[];
        for (final item in list) {
          out.add(VehicleListItem(item));
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
      UserApiPaths.vehicles,
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
      UserApiPaths.vehicleDocuments(vehicleId),
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['documents', 'items', 'rows'],
        );
        final out = <VehicleDocumentItem>[];
        for (final item in list) {
          out.add(VehicleDocumentItem(item));
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<SuperadminDocumentType>>> getVehicleDocumentTypes({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      PublicApiPaths.documentTypesForVehicle,
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final list = _extractMapList(
          data,
          extraKeys: const ['documentTypes', 'types'],
        );
        final out = <SuperadminDocumentType>[];
        for (final item in list) {
          out.add(SuperadminDocumentType.fromJson(item));
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
      UserApiPaths.vehicleDocuments(vehicleId),
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
      UserApiPaths.vehicleDetails(vehicleId),
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) =>
          Result.ok(UserVehicleDetails.fromRaw(_extractPayloadMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<MapVehiclePoint>>> getMapTelemetry({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      UserApiPaths.mapTelemetry,
      cancelToken: cancelToken,
    );
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
      UserApiPaths.vehicleByImeiDetails(imei),
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

  Map<String, dynamic> _extractPayloadMap(
    Object? data, {
    List<String> mapKeys = const [
      'data',
      'result',
      'item',
      'payload',
      'response',
      'vehicle',
      'details',
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
