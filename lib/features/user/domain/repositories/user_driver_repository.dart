import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/user/domain/entities/user_driver_details.dart';

abstract interface class UserDriverRepository {
  Future<Result<List<AdminDriverListItem>, AppError>> getDrivers();
  Future<Result<UserDriverDetails, AppError>> getDriverDetail(String id);
  Future<Result<AdminDriverListItem, AppError>> createDriver(Map<String, Object?> payload);
  Future<Result<void, AppError>> updateDriver(String id, Map<String, Object?> payload);
  Future<Result<void, AppError>> deleteDriver(String id);
}
