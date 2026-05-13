import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_admin_repository.dart';

class UpdateSuperadminAdminUseCase {
  const UpdateSuperadminAdminUseCase(this._repository);
  final SuperadminAdminRepository _repository;
  Future<Result<SuperadminAdminDetail, AppError>> call(String adminId, SuperadminAdminMutationInput input) => _repository.updateAdmin(adminId, input);
  Future<Result<void, AppError>> status(String adminId, bool isActive) => _repository.updateAdminStatus(adminId, isActive);
}
