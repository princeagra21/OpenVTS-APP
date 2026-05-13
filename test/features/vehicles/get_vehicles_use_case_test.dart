import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';
import 'package:open_vts/features/vehicles/domain/repositories/vehicle_repository.dart';
import 'package:open_vts/features/vehicles/domain/use_cases/get_vehicles_use_case.dart';
import 'package:open_vts/shared/models/paginated_response.dart';

class _FakeVehicleRepository implements VehicleRepository {
  _FakeVehicleRepository(this.result);
  final Result<PaginatedResponse<Vehicle>, AppError> result;

  @override
  Future<Result<PaginatedResponse<Vehicle>, AppError>> getVehicles({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async => result;
}

void main() {
  test('GetVehiclesUseCase returns vehicle page on success', () async {
    final page = PaginatedResponse<Vehicle>(
      data: const [Vehicle(id: 'v1', name: 'Truck 1')],
      total: 1,
    );
    final useCase = GetVehiclesUseCase(_FakeVehicleRepository(Result.success(page)));

    final result = await useCase();

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.data.single.id, 'v1');
  });

  test('GetVehiclesUseCase returns network error on failure', () async {
    final useCase = GetVehiclesUseCase(
      _FakeVehicleRepository(const Result.failure(NetworkError('offline'))),
    );

    final result = await useCase();

    expect(result.isFailure, true);
    expect(result.errorOrNull, isA<NetworkError>());
  });
}
