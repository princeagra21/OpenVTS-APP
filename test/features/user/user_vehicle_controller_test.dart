import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/di/user_vehicle_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';
import 'package:open_vts/features/user/domain/repositories/user_vehicle_repository.dart';
import 'package:open_vts/features/user/presentation/controllers/user_vehicle_detail_controller.dart';

void main() {
  test('loads vehicle detail into controller state', () async {
    final container = ProviderContainer(overrides: [userVehicleRepositoryProvider.overrideWithValue(_FakeUserVehicleRepository())]);
    addTearDown(container.dispose);

    await container.read(userVehicleDetailControllerProvider.notifier).load('veh-1');

    expect(container.read(userVehicleDetailControllerProvider).detail?.plateNumber, 'DL01AB1234');
  });
}

class _FakeUserVehicleRepository implements UserVehicleRepository {
  @override
  Future<Result<UserVehicleDetails, AppError>> getVehicleDetail(String id) async => Result.success(UserVehicleDetails(<String, dynamic>{'id': id, 'plateNumber': 'DL01AB1234'}));
}
