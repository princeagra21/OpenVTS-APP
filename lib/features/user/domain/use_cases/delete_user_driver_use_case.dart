import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/repositories/user_driver_repository.dart';

class DeleteUserDriverUseCase {
  const DeleteUserDriverUseCase(this._repository);
  final UserDriverRepository _repository;

  Future<Result<void, AppError>> call(String id) {
    return _repository.deleteDriver(id);
  }
}
