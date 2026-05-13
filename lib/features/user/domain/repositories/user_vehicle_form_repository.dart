import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/user/domain/entities/create_user_vehicle_input.dart';

abstract interface class UserVehicleFormRepository {
  Future<Result<List<ReferenceOption>, AppError>> getVehicleTypes();
  Future<Result<void, AppError>> createVehicle(CreateUserVehicleInput input);
}
