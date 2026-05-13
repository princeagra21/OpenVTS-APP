import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class UpdateAdminPasswordUseCase {
  const UpdateAdminPasswordUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<void, AppError>> call({required String currentPassword, required String newPassword}) {
    return _repository.updatePassword(currentPassword: currentPassword, newPassword: newPassword);
  }
}
