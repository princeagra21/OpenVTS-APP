import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/core/providers/repository_providers.dart' show sessionServiceProvider;
import 'package:open_vts/features/admin/data/mappers/admin_account_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_account_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_account_api_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_profile_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_user_detail_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_user_documents_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_user_linked_vehicles_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_user_linked_drivers_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_user_payments_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_user_tickets_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_users_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/login_as_admin_user_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/update_admin_password_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/update_admin_profile_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/update_admin_user_status_use_case.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_account_command_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_profile_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_user_detail_controller.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_user_list_controller.dart';

final adminAccountApiServiceProvider = Provider<AdminAccountApiService>((ref) {
  return AdminAccountApiService(ref.watch(appDioProvider));
});

final adminAccountMapperProvider = Provider<AdminAccountMapper>((ref) {
  return const AdminAccountMapper();
});

final adminAccountRepositoryProvider = Provider<AdminAccountRepository>((ref) {
  return AdminAccountRepositoryImpl(
    api: ref.watch(adminAccountApiServiceProvider),
    mapper: ref.watch(adminAccountMapperProvider),
  );
});

final getAdminUsersUseCaseProvider = Provider<GetAdminUsersUseCase>((ref) {
  return GetAdminUsersUseCase(ref.watch(adminAccountRepositoryProvider));
});

final getAdminUserDetailUseCaseProvider = Provider<GetAdminUserDetailUseCase>((ref) {
  return GetAdminUserDetailUseCase(ref.watch(adminAccountRepositoryProvider));
});

final updateAdminUserStatusUseCaseProvider = Provider<UpdateAdminUserStatusUseCase>((ref) {
  return UpdateAdminUserStatusUseCase(ref.watch(adminAccountRepositoryProvider));
});

final loginAsAdminUserUseCaseProvider = Provider<LoginAsAdminUserUseCase>((ref) {
  return LoginAsAdminUserUseCase(ref.watch(adminAccountRepositoryProvider));
});

final getAdminUserLinkedVehiclesUseCaseProvider = Provider<GetAdminUserLinkedVehiclesUseCase>((ref) {
  return GetAdminUserLinkedVehiclesUseCase(ref.watch(adminAccountRepositoryProvider));
});


final getAdminUserLinkedDriversUseCaseProvider = Provider<GetAdminUserLinkedDriversUseCase>((ref) {
  return GetAdminUserLinkedDriversUseCase(ref.watch(adminAccountRepositoryProvider));
});

final getAdminUserPaymentsUseCaseProvider = Provider<GetAdminUserPaymentsUseCase>((ref) {
  return GetAdminUserPaymentsUseCase(ref.watch(adminAccountRepositoryProvider));
});

final getAdminUserDocumentsUseCaseProvider = Provider<GetAdminUserDocumentsUseCase>((ref) {
  return GetAdminUserDocumentsUseCase(ref.watch(adminAccountRepositoryProvider));
});

final getAdminUserTicketsUseCaseProvider = Provider<GetAdminUserTicketsUseCase>((ref) {
  return GetAdminUserTicketsUseCase(ref.watch(adminAccountRepositoryProvider));
});

final getAdminProfileUseCaseProvider = Provider<GetAdminProfileUseCase>((ref) {
  return GetAdminProfileUseCase(ref.watch(adminAccountRepositoryProvider));
});

final updateAdminProfileUseCaseProvider = Provider<UpdateAdminProfileUseCase>((ref) {
  return UpdateAdminProfileUseCase(ref.watch(adminAccountRepositoryProvider));
});

final updateAdminPasswordUseCaseProvider = Provider<UpdateAdminPasswordUseCase>((ref) {
  return UpdateAdminPasswordUseCase(ref.watch(adminAccountRepositoryProvider));
});

final adminAccountCommandControllerProvider = Provider<AdminAccountCommandController>((ref) {
  return AdminAccountCommandController(
    repository: ref.watch(adminAccountRepositoryProvider),
    sessionService: ref.watch(sessionServiceProvider),
  );
});

final adminUserListControllerProvider = StateNotifierProvider.autoDispose<AdminUserListController, AdminUserListState>((ref) {
  return AdminUserListController(ref);
});

final adminUserDetailControllerProvider = StateNotifierProvider.autoDispose.family<AdminUserDetailController, AdminUserDetailState, String>((ref, userId) {
  final controller = AdminUserDetailController(ref, userId);
  controller.load();
  return controller;
});

final adminProfileControllerProvider = StateNotifierProvider.autoDispose<AdminProfileController, AdminProfileState>((ref) {
  final controller = AdminProfileController(ref);
  controller.load();
  return controller;
});
