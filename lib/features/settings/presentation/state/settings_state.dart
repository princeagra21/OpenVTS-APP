import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/settings/domain/entities/settings_snapshot.dart';

part 'settings_state.freezed.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = _Initial;
  const factory SettingsState.loading() = _Loading;
  const factory SettingsState.loaded({required SettingsSnapshot settings}) = _Loaded;
  const factory SettingsState.saving() = _Saving;
  const factory SettingsState.error(AppError error) = _Error;
}
