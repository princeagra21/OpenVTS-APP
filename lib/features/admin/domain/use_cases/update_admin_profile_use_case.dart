import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';
import 'package:open_vts/shared/models/admin_profile.dart';

class UpdateAdminProfileUseCase {
  const UpdateAdminProfileUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<AdminProfile, AppError>> call(Map<String, Object?> payload) {
    return _repository.updateMyProfile(payload);
  }
}
