import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/repositories/user_driver_repository.dart';

class UpdateUserDriverUseCase {
  const UpdateUserDriverUseCase(this._repository);
  final UserDriverRepository _repository;
  Future<Result<void, AppError>> call(String id, Map<String, Object?> payload) => _repository.updateDriver(id, payload);
}
