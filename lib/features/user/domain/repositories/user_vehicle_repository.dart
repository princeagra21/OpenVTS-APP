import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';

abstract interface class UserVehicleRepository {
  Future<Result<UserVehicleDetails, AppError>> getVehicleDetail(String id);
}
