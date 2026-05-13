import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_admin_repository.dart';

class UpdateSuperadminCompanyUseCase {
  const UpdateSuperadminCompanyUseCase(this._repository);
  final SuperadminAdminRepository _repository;

  Future<Result<void, AppError>> call(SuperadminAdminMutationInput input) {
    return _repository.updateCompanyDetails(input);
  }

  Future<Result<void, AppError>> config(
    String companyId,
    SuperadminAdminMutationInput input,
  ) {
    return _repository.updateCompanyConfig(companyId, input);
  }
}
