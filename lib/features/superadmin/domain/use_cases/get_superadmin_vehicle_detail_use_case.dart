import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_vehicle_repository.dart';

class GetSuperadminVehicleDetailUseCase {
  const GetSuperadminVehicleDetailUseCase(this._repository);
  final SuperadminVehicleRepository _repository;
  Future<Result<SuperadminVehicleDetail, AppError>> call(String vehicleId) => _repository.getVehicleDetail(vehicleId);
}
