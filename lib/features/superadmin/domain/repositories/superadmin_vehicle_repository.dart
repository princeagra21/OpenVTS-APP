import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';

abstract interface class SuperadminVehicleRepository {
  Future<Result<List<SuperadminVehicleListItem>, AppError>> getAdminVehicles(String adminId);
  Future<Result<List<SuperadminVehicleListItem>, AppError>> getVehicles({int? page, int? limit});
  Future<Result<SuperadminVehicleDetail, AppError>> getVehicleDetail(String vehicleId);
  Future<Result<List<SuperadminCommandOption>, AppError>> getCommandOptions(String imei);
  Future<Result<void, AppError>> sendCommand(String imei, String commandCode, Map<String, Object?>? payload, bool confirm);
  Future<Result<List<SuperadminSentCommand>, AppError>> getRecentCommands(String imei);
}
