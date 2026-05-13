import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_repository_impl.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_retrofit_service.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_repository.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_dashboard_use_case.dart';

final superadminApiServiceProvider = Provider<SuperadminApiService>((ref) {
  return SuperadminApiService(ref.watch(dioProvider));
});

final superadminRepositoryProvider = Provider<SuperadminRepository>((ref) {
  return SuperadminRepositoryImpl(api: ref.watch(superadminApiServiceProvider));
});

final getSuperadminDashboardUseCaseProvider = Provider<GetSuperadminDashboardUseCase>((ref) {
  return GetSuperadminDashboardUseCase(ref.watch(superadminRepositoryProvider));
});
