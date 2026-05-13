import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_vehicle_repository.dart';

class UnassignAdminVehicleDriverUseCase {
  const UnassignAdminVehicleDriverUseCase(this._repository);

  final AdminVehicleRepository _repository;

  Future<Result<void, AppError>> call(String vehicleId) {
    return _repository.unassignDriver(vehicleId);
  }
}
