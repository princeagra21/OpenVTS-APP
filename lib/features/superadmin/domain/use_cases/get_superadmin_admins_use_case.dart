import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_admin_repository.dart';

class GetSuperadminAdminsUseCase {
  const GetSuperadminAdminsUseCase(this._repository);
  final SuperadminAdminRepository _repository;
  Future<Result<List<SuperadminAdminListItem>, AppError>> call({int? page, int? limit, String? status}) {
    return _repository.getAdmins(page: page, limit: limit, status: status);
  }
}
