import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_details.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_vehicle_repository.dart';

class GetAdminVehicleDetailUseCase {
  const GetAdminVehicleDetailUseCase(this._repository);

  final AdminVehicleRepository _repository;

  Future<Result<AdminVehicleDetails, AppError>> call(String vehicleId) {
    return _repository.getVehicleDetail(vehicleId);
  }
}
