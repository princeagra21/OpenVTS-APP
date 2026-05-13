import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_retrofit_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_dashboard_use_case.dart';

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService(ref.watch(dioProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(api: ref.watch(adminApiServiceProvider));
});

final getAdminDashboardUseCaseProvider = Provider<GetAdminDashboardUseCase>((ref) {
  return GetAdminDashboardUseCase(ref.watch(adminRepositoryProvider));
});
