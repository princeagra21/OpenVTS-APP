import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';

abstract interface class UserSubUserRepository {
  Future<Result<List<UserSubUserItem>, AppError>> getSubUsers({int page = 1, int limit = 10});
  Future<Result<UserSubUserItem, AppError>> getSubUserDetail(String id);
  Future<Result<UserSubUserItem, AppError>> createSubUser(Map<String, Object?> payload);
  Future<Result<UserSubUserItem, AppError>> updateSubUser(String id, Map<String, Object?> payload);
  Future<Result<void, AppError>> deleteSubUser(String id);
  Future<Result<List<Map<String, Object?>>, AppError>> getSubUserVehicles(String id);
  Future<Result<void, AppError>> assignVehicle(String id, List<int> vehicleIds);
  Future<Result<void, AppError>> unassignVehicle(String id, List<int> vehicleIds);
}
