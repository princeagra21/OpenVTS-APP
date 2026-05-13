import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_details.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class GetAdminUserDetailUseCase {
  const GetAdminUserDetailUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<AdminUserDetails, AppError>> call(String userId) {
    return _repository.getUserDetails(userId);
  }
}
