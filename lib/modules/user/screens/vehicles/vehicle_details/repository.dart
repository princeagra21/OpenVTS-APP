import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:open_vts/core/models/superadmin_document_type.dart';
import 'package:open_vts/core/models/user_vehicle_details.dart';
import 'package:open_vts/core/models/vehicle_document_item.dart';
import 'package:open_vts/core/network/api_paths.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/user_vehicles_repository.dart';

class VehicleDetailsRepository {
  const VehicleDetailsRepository({required UserVehiclesRepository delegate})
    : _delegate = delegate;

  final UserVehiclesRepository _delegate;

  Future<Result<UserVehicleDetails>> getVehicleDetails(
    String vehicleId, {
    CancelToken? cancelToken,
  }) {
    return _delegate.getVehicleDetails(vehicleId, cancelToken: cancelToken);
  }

  Future<Result<List<VehicleDocumentItem>>> getVehicleDocuments(
    String vehicleId, {
    CancelToken? cancelToken,
  }) {
    return _delegate.getVehicleDocuments(vehicleId, cancelToken: cancelToken);
  }

  Future<Result<List<SuperadminDocumentType>>> getVehicleDocumentTypes({
    CancelToken? cancelToken,
  }) {
    return _delegate.getVehicleDocumentTypes(cancelToken: cancelToken);
  }

  Future<Result<void>> uploadVehicleDocument({
    required String vehicleId,
    required String title,
    required int docTypeId,
    required Uint8List fileBytes,
    required String filename,
    String? tags,
    String? expiryAt,
    bool isVisible = true,
    CancelToken? cancelToken,
  }) {
    return _delegate.uploadVehicleDocument(
      vehicleId: vehicleId,
      title: title,
      docTypeId: docTypeId,
      fileBytes: fileBytes,
      filename: filename,
      tags: tags,
      expiryAt: expiryAt,
      isVisible: isVisible,
      cancelToken: cancelToken,
    );
  }

  Future<Result<void>> updateVehicleConfig({
    required String vehicleId,
    required Map<String, dynamic> payload,
    CancelToken? cancelToken,
  }) async {
    final result = await _delegate.api.patch(
      ApiPaths.path('/user/vehicles/$vehicleId/config'),
      data: payload,
      cancelToken: cancelToken,
    );

    return result.when(
      success: (_) => Result.ok(null),
      failure: (error) => Result.fail(error),
    );
  }
}
