import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_admin_repository.dart';

class LoginAsSuperadminAdminUseCase {
  const LoginAsSuperadminAdminUseCase(this._repository);
  final SuperadminAdminRepository _repository;

  Future<Result<String, AppError>> call(String adminId) {
    return _repository.loginAsAdmin(adminId);
  }
}
