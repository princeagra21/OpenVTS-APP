import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';
import 'package:open_vts/features/user/domain/repositories/user_vehicle_repository.dart';

class GetUserVehicleDetailUseCase {
  const GetUserVehicleDetailUseCase(this._repository);
  final UserVehicleRepository _repository;
  Future<Result<UserVehicleDetails, AppError>> call(String id) => _repository.getVehicleDetail(id);
}
