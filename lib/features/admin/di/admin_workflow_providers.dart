import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_device_providers.dart' as admin_device_di;
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/admin/data/mappers/admin_workflow_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_device_form_repository_impl.dart';
import 'package:open_vts/features/admin/data/repositories/admin_driver_form_repository_impl.dart';
import 'package:open_vts/features/admin/data/repositories/admin_team_form_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_workflow_api_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_form_repository.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_form_repository.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_form_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_device_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_driver_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_team_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_driver_users_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/load_admin_device_form_data_use_case.dart';

final adminWorkflowApiServiceProvider = Provider<AdminWorkflowApiService>((ref) {
  return AdminWorkflowApiService(ref.watch(appDioProvider));
});

final adminWorkflowMapperProvider = Provider<AdminWorkflowMapper>((ref) {
  return const AdminWorkflowMapper();
});

final adminDriverFormRepositoryProvider = Provider<AdminDriverFormRepository>((ref) {
  return AdminDriverFormRepositoryImpl(
    api: ref.watch(adminWorkflowApiServiceProvider),
    mapper: ref.watch(adminWorkflowMapperProvider),
  );
});

final adminDeviceFormRepositoryProvider = Provider<AdminDeviceFormRepository>((ref) {
  return AdminDeviceFormRepositoryImpl(
    api: ref.watch(adminWorkflowApiServiceProvider),
    mapper: ref.watch(adminWorkflowMapperProvider),
  );
});

final adminTeamFormRepositoryProvider = Provider<AdminTeamFormRepository>((ref) {
  return AdminTeamFormRepositoryImpl(api: ref.watch(adminWorkflowApiServiceProvider));
});

final getAdminDriverUsersUseCaseProvider = Provider<GetAdminDriverUsersUseCase>((ref) {
  return GetAdminDriverUsersUseCase(ref.watch(adminDriverFormRepositoryProvider));
});

final createAdminDriverUseCaseProvider = Provider<CreateAdminDriverUseCase>((ref) {
  return CreateAdminDriverUseCase(ref.watch(adminDriverFormRepositoryProvider));
});

final loadAdminDeviceFormDataUseCaseProvider = Provider<LoadAdminDeviceFormDataUseCase>((ref) {
  return LoadAdminDeviceFormDataUseCase(ref.watch(adminDeviceFormRepositoryProvider));
});

final createAdminDeviceUseCaseProvider = Provider<CreateAdminDeviceUseCase>((ref) {
  return CreateAdminDeviceUseCase(ref.watch(admin_device_di.adminDeviceRepositoryProvider));
});

final createAdminTeamUseCaseProvider = Provider<CreateAdminTeamUseCase>((ref) {
  return CreateAdminTeamUseCase(ref.watch(adminTeamFormRepositoryProvider));
});
