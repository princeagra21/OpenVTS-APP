import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class LoginAsAdminUserUseCase {
  const LoginAsAdminUserUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<String, AppError>> call(String userId) {
    return _repository.loginAsUser(userId);
  }
}
