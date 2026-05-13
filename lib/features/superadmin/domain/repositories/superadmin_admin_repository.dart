import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';

abstract interface class SuperadminAdminRepository {
  Future<Result<List<SuperadminAdminListItem>, AppError>> getAdmins({int? page, int? limit, String? status});
  Future<Result<SuperadminAdminDetail, AppError>> getAdminDetail(String adminId);
  Future<Result<void, AppError>> createAdmin(SuperadminAdminMutationInput input);
  Future<Result<SuperadminAdminDetail, AppError>> updateAdmin(String adminId, SuperadminAdminMutationInput input);
  Future<Result<void, AppError>> updateAdminStatus(String adminId, bool isActive);
  Future<Result<void, AppError>> updateCompanyDetails(SuperadminAdminMutationInput input);
  Future<Result<void, AppError>> updateCompanyConfig(String companyId, SuperadminAdminMutationInput input);
  Future<Result<String, AppError>> loginAsAdmin(String adminId);
}
