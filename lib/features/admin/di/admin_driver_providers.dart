import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/admin/data/mappers/admin_driver_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_driver_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_driver_api_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_driver_detail_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_drivers_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/assign_admin_driver_user_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_driver_documents_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_driver_linked_users_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_driver_unlinked_users_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/unassign_admin_driver_user_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/update_admin_driver_use_case.dart';

final adminDriverApiServiceProvider = Provider<AdminDriverApiService>((ref) {
  return AdminDriverApiService(ref.watch(appDioProvider));
});

final adminDriverMapperProvider = Provider<AdminDriverMapper>((ref) => const AdminDriverMapper());

final adminDriverRepositoryProvider = Provider<AdminDriverRepository>((ref) {
  return AdminDriverRepositoryImpl(
    api: ref.watch(adminDriverApiServiceProvider),
    mapper: ref.watch(adminDriverMapperProvider),
  );
});

final getAdminDriversUseCaseProvider = Provider<GetAdminDriversUseCase>((ref) {
  return GetAdminDriversUseCase(ref.watch(adminDriverRepositoryProvider));
});

final getAdminDriverDetailUseCaseProvider = Provider<GetAdminDriverDetailUseCase>((ref) {
  return GetAdminDriverDetailUseCase(ref.watch(adminDriverRepositoryProvider));
});

final updateAdminDriverUseCaseProvider = Provider<UpdateAdminDriverUseCase>((ref) {
  return UpdateAdminDriverUseCase(ref.watch(adminDriverRepositoryProvider));
});


final getAdminDriverDocumentsUseCaseProvider = Provider<GetAdminDriverDocumentsUseCase>((ref) {
  return GetAdminDriverDocumentsUseCase(ref.watch(adminDriverRepositoryProvider));
});

final getAdminDriverLinkedUsersUseCaseProvider = Provider<GetAdminDriverLinkedUsersUseCase>((ref) {
  return GetAdminDriverLinkedUsersUseCase(ref.watch(adminDriverRepositoryProvider));
});

final getAdminDriverUnlinkedUsersUseCaseProvider = Provider<GetAdminDriverUnlinkedUsersUseCase>((ref) {
  return GetAdminDriverUnlinkedUsersUseCase(ref.watch(adminDriverRepositoryProvider));
});

final assignAdminDriverUserUseCaseProvider = Provider<AssignAdminDriverUserUseCase>((ref) {
  return AssignAdminDriverUserUseCase(ref.watch(adminDriverRepositoryProvider));
});

final unassignAdminDriverUserUseCaseProvider = Provider<UnassignAdminDriverUserUseCase>((ref) {
  return UnassignAdminDriverUserUseCase(ref.watch(adminDriverRepositoryProvider));
});
