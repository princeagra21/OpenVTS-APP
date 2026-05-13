import 'dart:typed_data';

import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_document_item.dart';
import 'package:open_vts/core/services/api_paths_facade.dart';
import 'package:open_vts/core/utils/presentation_result.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicles_repository.dart';

class VehicleDetailsRepository {
  const VehicleDetailsRepository({required UserVehiclesRepository delegate})
    : _delegate = delegate;

  final UserVehiclesRepository _delegate;

  Future<Result<UserVehicleDetails>> getVehicleDetails(
    String vehicleId, {
    AppCancellationHandle? cancelToken,
  }) {
    return _delegate.getVehicleDetails(vehicleId, cancelToken: cancelToken);
  }

  Future<Result<List<VehicleDocumentItem>>> getVehicleDocuments(
    String vehicleId, {
    AppCancellationHandle? cancelToken,
  }) {
    return _delegate.getVehicleDocuments(vehicleId, cancelToken: cancelToken);
  }

  Future<Result<List<SuperadminDocumentType>>> getVehicleDocumentTypes({
    AppCancellationHandle? cancelToken,
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
    AppCancellationHandle? cancelToken,
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
    AppCancellationHandle? cancelToken,
  }) async {
    final result = await _delegate.api.patch(
      UserApiPaths.vehicleConfig(vehicleId),
      data: payload,
      cancelToken: cancelToken,
    );

    return result.when(
      success: (_) => Result.ok(null),
      failure: (error) => Result.fail(error),
    );
  }
}
