import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_settings.dart';

abstract interface class SuperadminSettingsRepository {
  Future<Result<SuperadminSettingsData, AppError>> getSettings(String adminId);
  Future<Result<SuperadminSettingsData, AppError>> updateSettings(String adminId, SuperadminSettingsData settings);
  Future<Result<List<SuperadminRole>, AppError>> getRoles();
  Future<Result<SuperadminRole, AppError>> updateRole(SuperadminRoleMutationInput input);
}
