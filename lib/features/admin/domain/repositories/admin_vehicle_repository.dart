import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_log_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';

abstract interface class AdminVehicleRepository {
  Future<Result<AdminVehicleDetails, AppError>> getVehicleDetail(String vehicleId);

  Future<Result<List<AdminUserListItem>, AppError>> getLinkedUsers(String vehicleId);

  Future<Result<List<AdminDocumentItem>, AppError>> getVehicleDocuments(String vehicleId);

  Future<Result<VehicleConfig, AppError>> getVehicleConfig(String vehicleId);

  Future<Result<void, AppError>> updateVehicleConfig(String vehicleId, VehicleConfigUpdate payload);

  Future<Result<List<AdminVehicleLogItem>, AppError>> getVehicleLogsByImei(
    String imei, {
    Map<String, Object?>? query,
  });

  Future<Result<void, AppError>> updateVehicleStatus(String vehicleId, bool isActive);

  Future<Result<void, AppError>> deleteVehicle(String vehicleId);

  Future<Result<void, AppError>> assignDriver(String vehicleId, {required String driverId});

  Future<Result<void, AppError>> unassignDriver(String vehicleId);
}
