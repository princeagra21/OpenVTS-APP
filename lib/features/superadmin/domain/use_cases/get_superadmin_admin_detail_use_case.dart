import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_admin_repository.dart';

class GetSuperadminAdminDetailUseCase {
  const GetSuperadminAdminDetailUseCase(this._repository);
  final SuperadminAdminRepository _repository;
  Future<Result<SuperadminAdminDetail, AppError>> call(String adminId) => _repository.getAdminDetail(adminId);
}
