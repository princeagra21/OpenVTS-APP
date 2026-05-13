import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:open_vts/features/settings/data/sources/settings_retrofit_service.dart';
import 'package:open_vts/features/settings/domain/repositories/settings_repository.dart';
import 'package:open_vts/features/settings/domain/use_cases/get_settings_use_case.dart';
import 'package:open_vts/features/settings/domain/use_cases/update_settings_use_case.dart';

final settingsApiServiceProvider = Provider<SettingsApiService>((ref) {
  return SettingsApiService(ref.watch(dioProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(api: ref.watch(settingsApiServiceProvider));
});

final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>((ref) {
  return GetSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

final updateSettingsUseCaseProvider = Provider<UpdateSettingsUseCase>((ref) {
  return UpdateSettingsUseCase(ref.watch(settingsRepositoryProvider));
});
