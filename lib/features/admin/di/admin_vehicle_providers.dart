import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/admin/data/mappers/admin_vehicle_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_vehicle_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_vehicle_api_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_vehicle_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/assign_admin_vehicle_driver_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/delete_admin_vehicle_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_vehicle_detail_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_vehicle_documents_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_vehicle_linked_users_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_vehicle_logs_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/unassign_admin_vehicle_driver_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/update_admin_vehicle_config_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/update_admin_vehicle_status_use_case.dart';

final adminVehicleApiServiceProvider = Provider<AdminVehicleApiService>((ref) {
  return AdminVehicleApiService(ref.watch(appDioProvider));
});

final adminVehicleMapperProvider = Provider<AdminVehicleMapper>((ref) => const AdminVehicleMapper());

final adminVehicleRepositoryProvider = Provider<AdminVehicleRepository>((ref) {
  return AdminVehicleRepositoryImpl(
    api: ref.watch(adminVehicleApiServiceProvider),
    mapper: ref.watch(adminVehicleMapperProvider),
  );
});

final getAdminVehicleDetailUseCaseProvider = Provider<GetAdminVehicleDetailUseCase>((ref) {
  return GetAdminVehicleDetailUseCase(ref.watch(adminVehicleRepositoryProvider));
});

final getAdminVehicleLinkedUsersUseCaseProvider = Provider<GetAdminVehicleLinkedUsersUseCase>((ref) {
  return GetAdminVehicleLinkedUsersUseCase(ref.watch(adminVehicleRepositoryProvider));
});

final getAdminVehicleDocumentsUseCaseProvider = Provider<GetAdminVehicleDocumentsUseCase>((ref) {
  return GetAdminVehicleDocumentsUseCase(ref.watch(adminVehicleRepositoryProvider));
});

final getAdminVehicleLogsUseCaseProvider = Provider<GetAdminVehicleLogsUseCase>((ref) {
  return GetAdminVehicleLogsUseCase(ref.watch(adminVehicleRepositoryProvider));
});

final updateAdminVehicleConfigUseCaseProvider = Provider<UpdateAdminVehicleConfigUseCase>((ref) {
  return UpdateAdminVehicleConfigUseCase(ref.watch(adminVehicleRepositoryProvider));
});

final updateAdminVehicleStatusUseCaseProvider = Provider<UpdateAdminVehicleStatusUseCase>((ref) {
  return UpdateAdminVehicleStatusUseCase(ref.watch(adminVehicleRepositoryProvider));
});

final deleteAdminVehicleUseCaseProvider = Provider<DeleteAdminVehicleUseCase>((ref) {
  return DeleteAdminVehicleUseCase(ref.watch(adminVehicleRepositoryProvider));
});

final assignAdminVehicleDriverUseCaseProvider = Provider<AssignAdminVehicleDriverUseCase>((ref) {
  return AssignAdminVehicleDriverUseCase(ref.watch(adminVehicleRepositoryProvider));
});

final unassignAdminVehicleDriverUseCaseProvider = Provider<UnassignAdminVehicleDriverUseCase>((ref) {
  return UnassignAdminVehicleDriverUseCase(ref.watch(adminVehicleRepositoryProvider));
});
