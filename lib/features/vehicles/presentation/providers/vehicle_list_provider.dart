import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/vehicles/di/vehicles_providers.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';
import 'package:open_vts/shared/models/paginated_response.dart';

final vehicleListProvider = FutureProvider.autoDispose
    .family<PaginatedResponse<Vehicle>, VehicleListQuery>((ref, query) async {
  final useCase = ref.watch(getVehiclesUseCaseProvider);
  final result = await useCase(
    page: query.page,
    limit: query.limit,
    search: query.search,
    status: query.status,
  );
  return result.when(
    success: (value) => value,
    failure: (error) => throw error,
  );
});

class VehicleListQuery {
  const VehicleListQuery({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.status,
  });

  final int page;
  final int limit;
  final String? search;
  final String? status;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VehicleListQuery &&
            other.page == page &&
            other.limit == limit &&
            other.search == search &&
            other.status == status;
  }

  @override
  int get hashCode => Object.hash(page, limit, search, status);
}
