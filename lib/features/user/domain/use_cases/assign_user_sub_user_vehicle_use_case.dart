import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/repositories/user_sub_user_repository.dart';

class AssignUserSubUserVehicleUseCase {
  const AssignUserSubUserVehicleUseCase(this._repository);
  final UserSubUserRepository _repository;

  Future<Result<void, AppError>> call(String id, List<int> vehicleIds) {
    return _repository.assignVehicle(id, vehicleIds);
  }
}
