import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_vehicle_repository.dart';

class AssignAdminVehicleDriverUseCase {
  const AssignAdminVehicleDriverUseCase(this._repository);

  final AdminVehicleRepository _repository;

  Future<Result<void, AppError>> call(String vehicleId, {required String driverId}) {
    return _repository.assignDriver(vehicleId, driverId: driverId);
  }
}
