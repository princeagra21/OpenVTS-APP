import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_vehicle_repository.dart';

class GetSuperadminVehiclesUseCase {
  const GetSuperadminVehiclesUseCase(this._repository);
  final SuperadminVehicleRepository _repository;
  Future<Result<List<SuperadminVehicleListItem>, AppError>> call({String? adminId, int? page, int? limit}) {
    if (adminId != null && adminId.trim().isNotEmpty) return _repository.getAdminVehicles(adminId);
    return _repository.getVehicles(page: page, limit: limit);
  }
}
