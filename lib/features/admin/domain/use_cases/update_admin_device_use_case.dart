import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_repository.dart';

class UpdateAdminDeviceUseCase {
  const UpdateAdminDeviceUseCase(this._repository);
  final AdminDeviceRepository _repository;
  Future<Result<void, AppError>> call(String deviceId, UpdateAdminDeviceMutationInput input) => _repository.updateDevice(deviceId, input);
}
