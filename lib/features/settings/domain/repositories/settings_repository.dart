import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/settings/domain/entities/settings_snapshot.dart';

abstract interface class SettingsRepository {
  Future<Result<SettingsSnapshot, AppError>> getSettings();

  Future<Result<SettingsSnapshot, AppError>> updateSettings(Map<String, Object?> values);
}
