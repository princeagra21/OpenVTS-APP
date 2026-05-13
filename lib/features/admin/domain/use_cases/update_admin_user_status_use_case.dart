import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class UpdateAdminUserStatusUseCase {
  const UpdateAdminUserStatusUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<void, AppError>> call(String userId, bool isActive) {
    return _repository.updateUserStatus(userId, isActive);
  }
}
