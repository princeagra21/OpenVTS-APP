import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_role_mapper.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_settings_mapper.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_settings_repository_impl.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_settings_api_service.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_settings_repository.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_roles_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_settings_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/update_superadmin_role_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/update_superadmin_settings_use_case.dart';

final superadminSettingsApiServiceProvider = Provider<SuperadminSettingsApiService>((ref) {
  return SuperadminSettingsApiService(ref.watch(appDioProvider));
});

final superadminSettingsMapperProvider = Provider<SuperadminSettingsMapper>((ref) => const SuperadminSettingsMapper());
final superadminRoleMapperProvider = Provider<SuperadminRoleMapper>((ref) => const SuperadminRoleMapper());

final superadminSettingsRepositoryProvider = Provider<SuperadminSettingsRepository>((ref) {
  return SuperadminSettingsRepositoryImpl(
    api: ref.watch(superadminSettingsApiServiceProvider),
    settingsMapper: ref.watch(superadminSettingsMapperProvider),
    roleMapper: ref.watch(superadminRoleMapperProvider),
  );
});

final getSuperadminSettingsUseCaseProvider = Provider<GetSuperadminSettingsUseCase>((ref) {
  return GetSuperadminSettingsUseCase(ref.watch(superadminSettingsRepositoryProvider));
});

final updateSuperadminSettingsUseCaseProvider = Provider<UpdateSuperadminSettingsUseCase>((ref) {
  return UpdateSuperadminSettingsUseCase(ref.watch(superadminSettingsRepositoryProvider));
});

final getSuperadminRolesUseCaseProvider = Provider<GetSuperadminRolesUseCase>((ref) {
  return GetSuperadminRolesUseCase(ref.watch(superadminSettingsRepositoryProvider));
});

final updateSuperadminRoleUseCaseProvider = Provider<UpdateSuperadminRoleUseCase>((ref) {
  return UpdateSuperadminRoleUseCase(ref.watch(superadminSettingsRepositoryProvider));
});
