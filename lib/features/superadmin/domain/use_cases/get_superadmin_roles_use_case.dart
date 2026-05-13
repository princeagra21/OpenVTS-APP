import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_settings.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_settings_repository.dart';

class GetSuperadminRolesUseCase {
  const GetSuperadminRolesUseCase(this._repository);
  final SuperadminSettingsRepository _repository;
  Future<Result<List<SuperadminRole>, AppError>> call() => _repository.getRoles();
}
