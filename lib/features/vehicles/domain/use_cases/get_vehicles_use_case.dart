import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';
import 'package:open_vts/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:open_vts/shared/models/paginated_response.dart';

class GetVehiclesUseCase {
  const GetVehiclesUseCase(this.repository);
  final VehicleRepository repository;

  Future<Result<PaginatedResponse<Vehicle>, AppError>> call({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return repository.getVehicles(
      page: page,
      limit: limit,
      search: search,
      status: status,
    );
  }
}
