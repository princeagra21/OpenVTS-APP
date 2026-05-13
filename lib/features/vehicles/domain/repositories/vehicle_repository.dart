import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';
import 'package:open_vts/shared/models/paginated_response.dart';

abstract interface class VehicleRepository {
  Future<Result<PaginatedResponse<Vehicle>, AppError>> getVehicles({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  });
}
