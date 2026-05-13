import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/admin/data/mappers/admin_form_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_form_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_form_api_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_form_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_user_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/create_admin_vehicle_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/load_add_vehicle_form_data_use_case.dart';

final adminFormApiServiceProvider = Provider<AdminFormApiService>((ref) {
  return AdminFormApiService(ref.watch(appDioProvider));
});

final adminFormMapperProvider = Provider<AdminFormMapper>((ref) {
  return const AdminFormMapper();
});

final adminFormRepositoryProvider = Provider<AdminFormRepository>((ref) {
  return AdminFormRepositoryImpl(
    api: ref.watch(adminFormApiServiceProvider),
    mapper: ref.watch(adminFormMapperProvider),
  );
});

final loadAddVehicleFormDataUseCaseProvider = Provider<LoadAddVehicleFormDataUseCase>((ref) {
  return LoadAddVehicleFormDataUseCase(ref.watch(adminFormRepositoryProvider));
});

final createAdminVehicleUseCaseProvider = Provider<CreateAdminVehicleUseCase>((ref) {
  return CreateAdminVehicleUseCase(ref.watch(adminFormRepositoryProvider));
});

final createAdminUserUseCaseProvider = Provider<CreateAdminUserUseCase>((ref) {
  return CreateAdminUserUseCase(ref.watch(adminFormRepositoryProvider));
});
