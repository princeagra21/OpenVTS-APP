export 'legacy_repository_adapter_providers.dart';
export 'core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/api/common_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_transactions_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_landmarks_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_routes_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_transactions_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_notification_preferences_repository.dart';
import 'package:open_vts/core/session/session_service.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/features/admin/data/sources/admin_typed_api_transport.dart';
import 'package:open_vts/features/user/data/sources/user_typed_api_transport.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_typed_api_transport.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/features/admin/data/repositories/admin_profile_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_users_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_vehicles_repository.dart';
import 'package:open_vts/features/admin/data/repositories/role_notifications_repository.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_repository.dart';
import 'package:open_vts/features/support/data/repositories/support_repository.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/user/data/repositories/user_profile_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicles_repository.dart';
import 'package:open_vts/features/vehicles/data/repositories/legacy_vehicle_repository.dart' as legacy_vehicle;
import 'package:open_vts/features/vehicles/data/repositories/vehicle_repository_impl.dart';
import 'package:open_vts/features/vehicles/domain/permissions/vehicle_permissions.dart' as vehicle_permissions;
import 'package:open_vts/features/vehicles/domain/repositories/vehicle_repository.dart';

final coreAdminTypedApiTransportProvider = Provider<AdminTypedApiTransport>((ref) {
  return AdminTypedApiTransport.fromDio(ref.watch(dioProvider));
});

final coreUserTypedApiTransportProvider = Provider<UserTypedApiTransport>((ref) {
  return UserTypedApiTransport.fromDio(ref.watch(dioProvider));
});

final coreSuperadminTypedApiTransportProvider = Provider<SuperadminTypedApiTransport>((ref) {
  return SuperadminTypedApiTransport.fromDio(ref.watch(dioProvider));
});

/// Central bridge from the legacy DI container into Riverpod.
///
/// Presentation code should depend on these providers, domain use cases, or
/// feature-specific providers instead of calling `AppContainer.instance`.
final tokenStorageProvider = Provider<TokenStorageBase>((ref) {
  return ref.watch(appContainerProvider).tokenStorage;
});

final pushNotificationsServiceProvider = Provider<PushNotificationsService>((ref) {
  return ref.watch(appContainerProvider).pushNotificationsService;
});

final commonRepositoryProvider = Provider<CommonRepository>((ref) {
  return CommonRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(api: ref.watch(coreAdminTypedApiTransportProvider));
});

final adminVehiclesRepositoryProvider = Provider<AdminVehiclesRepository>((ref) {
  return ref.watch(appContainerProvider).adminVehiclesRepository;
});

final adminProfileRepositoryProvider = Provider<AdminProfileRepository>((ref) {
  return AdminProfileRepository(api: ref.watch(coreAdminTypedApiTransportProvider));
});

final superadminRepositoryProvider = Provider<SuperadminRepository>((ref) {
  return SuperadminRepository(api: ref.watch(coreSuperadminTypedApiTransportProvider));
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(api: ref.watch(coreUserTypedApiTransportProvider));
});

final userVehiclesRepositoryProvider = Provider<UserVehiclesRepository>((ref) {
  return UserVehiclesRepository(api: ref.watch(coreUserTypedApiTransportProvider));
});

final roleNotificationsRepositoryProvider = Provider.family<RoleNotificationsRepository, String>((ref, pathPrefix) {
  return RoleNotificationsRepository(
    api: ref.watch(legacyApiTransportProvider),
    pathPrefix: pathPrefix,
  );
});

final supportRepositoryAdapterProvider = Provider.family<SupportRepositoryAdapter, SupportRole>((ref, role) {
  return SupportRepositoryFactory.forRole(role);
});

final selectedVehicleRoleProvider = StateProvider<vehicle_permissions.VehicleRole>((ref) {
  return vehicle_permissions.VehicleRole.user;
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final role = ref.watch(selectedVehicleRoleProvider);
  return VehicleRepositoryImpl(legacyRepository: legacy_vehicle.VehicleRepositoryFactory.create(role));
});

final vehicleLegacyRepositoryFactoryProvider = Provider<dynamic Function(vehicle_permissions.VehicleRole)>((ref) {
  return (role) => legacy_vehicle.VehicleRepositoryFactory.create(role);
});

final appConfigProvider = Provider<AppConfig>((ref) {
  return ref.watch(appContainerProvider).appConfig;
});

final sessionServiceProvider = Provider<SessionService>((ref) {
  return ref.watch(appContainerProvider).sessionService;
});

final userNotificationPreferencesRepositoryProvider = Provider<UserNotificationPreferencesRepository>((ref) {
  return ref.watch(appContainerProvider).userNotificationPreferencesRepository;
});

final adminTransactionsRepositoryProvider = Provider<AdminTransactionsRepository>((ref) {
  return AdminTransactionsRepository(api: ref.watch(coreAdminTypedApiTransportProvider));
});

final userLandmarksRepositoryProvider = Provider<UserLandmarksRepository>((ref) {
  return ref.watch(appContainerProvider).userLandmarksRepository;
});

final userRoutesRepositoryProvider = Provider<UserRoutesRepository>((ref) {
  return ref.watch(appContainerProvider).userRoutesRepository;
});

final userTransactionsRepositoryProvider = Provider<UserTransactionsRepository>((ref) {
  return ref.watch(appContainerProvider).userTransactionsRepository;
});


class BaseUrlUpdater {
  const BaseUrlUpdater(this._update);
  final void Function(String baseUrl) _update;
  void updateBaseUrl(String baseUrl) => _update(baseUrl);
}

final baseUrlUpdaterProvider = Provider<BaseUrlUpdater>((ref) {
  return BaseUrlUpdater(ref.watch(apiClientProvider).updateBaseUrl);
});
