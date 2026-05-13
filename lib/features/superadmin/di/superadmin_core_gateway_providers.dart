import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart' show legacyApiTransportProvider;
import 'package:open_vts/core/providers/repository_providers.dart' show appConfigProvider, sessionServiceProvider;
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart' show referenceDataRepositoryProvider;
import 'package:open_vts/features/superadmin/data/repositories/superadmin_core_gateway_repository_impl.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_core_gateway_repository.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/superadmin_core_gateway_use_cases.dart';
import 'package:open_vts/features/superadmin/presentation/controllers/superadmin_dashboard_controller.dart';

final superadminCoreGatewayRepositoryProvider = Provider<SuperadminCoreGatewayRepository>((ref) {
  return SuperadminCoreGatewayRepositoryImpl(
    api: ref.watch(legacyApiTransportProvider),
    referenceDataRepository: ref.watch(referenceDataRepositoryProvider),
  );
});

final getSuperadminProfileGatewayUseCaseProvider = Provider<GetSuperadminProfileGatewayUseCase>((ref) {
  return GetSuperadminProfileGatewayUseCase(ref.watch(superadminCoreGatewayRepositoryProvider));
});

final updateSuperadminPasswordGatewayUseCaseProvider = Provider<UpdateSuperadminPasswordGatewayUseCase>((ref) {
  return UpdateSuperadminPasswordGatewayUseCase(ref.watch(superadminCoreGatewayRepositoryProvider));
});

final getSuperadminDashboardGatewayUseCaseProvider = Provider<GetSuperadminDashboardGatewayUseCase>((ref) {
  return GetSuperadminDashboardGatewayUseCase(ref.watch(superadminCoreGatewayRepositoryProvider));
});

final getSuperadminAdminGatewayUseCaseProvider = Provider<GetSuperadminAdminGatewayUseCase>((ref) {
  return GetSuperadminAdminGatewayUseCase(ref.watch(superadminCoreGatewayRepositoryProvider));
});

final superadminVehicleGatewayUseCaseProvider = Provider<SuperadminVehicleGatewayUseCase>((ref) {
  return SuperadminVehicleGatewayUseCase(ref.watch(superadminCoreGatewayRepositoryProvider));
});

final superadminReferenceOptionsGatewayUseCaseProvider = Provider<SuperadminReferenceOptionsGatewayUseCase>((ref) {
  return SuperadminReferenceOptionsGatewayUseCase(ref.watch(superadminCoreGatewayRepositoryProvider));
});

final superadminPreferencesGatewayUseCaseProvider = Provider<SuperadminPreferencesGatewayUseCase>((ref) {
  return SuperadminPreferencesGatewayUseCase(ref.watch(superadminCoreGatewayRepositoryProvider));
});

final superadminGatewayAppConfigProvider = appConfigProvider;
final superadminGatewaySessionServiceProvider = sessionServiceProvider;


final superadminDashboardControllerProvider = StateNotifierProvider.autoDispose<SuperadminDashboardController, SuperadminDashboardState>((ref) {
  final controller = SuperadminDashboardController(
    ref.watch(getSuperadminDashboardGatewayUseCaseProvider),
  );
  controller.loadInitial();
  return controller;
});
