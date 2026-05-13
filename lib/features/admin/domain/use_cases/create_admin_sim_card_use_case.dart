import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_repository.dart';

class CreateAdminSimCardUseCase {
  const CreateAdminSimCardUseCase(this._repository);

  final AdminDeviceRepository _repository;

  Future<Result<void, AppError>> call(CreateAdminSimCardMutationInput input) {
    return _repository.createSimCard(input);
  }
}
