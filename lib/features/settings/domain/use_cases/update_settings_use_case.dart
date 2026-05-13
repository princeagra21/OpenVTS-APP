import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/settings/domain/entities/settings_snapshot.dart';
import 'package:open_vts/features/settings/domain/repositories/settings_repository.dart';

class UpdateSettingsUseCase {
  const UpdateSettingsUseCase(this.repository);

  final SettingsRepository repository;

  Future<Result<SettingsSnapshot, AppError>> call(Map<String, Object?> values) {
    return repository.updateSettings(values);
  }
}
