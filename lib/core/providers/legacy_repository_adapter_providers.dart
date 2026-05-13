/// Transitional repository type exports for legacy screens while they are
/// migrated behind feature-specific controllers/notifiers.
export 'package:open_vts/features/admin_tools/data/repositories/api_config_repository.dart';
export 'package:open_vts/features/settings/data/repositories/app_preferences_repository.dart';
export 'package:open_vts/features/settings/data/repositories/white_label_repository.dart';
export 'package:open_vts/features/auth/data/repositories/auth_repository.dart';
export 'package:open_vts/features/auth/data/repositories/push_token_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_app_preferences_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_calendar_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_dashboard_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_devices_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_drivers_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_localization_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_logs_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_notification_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_notifications_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_payments_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_pricing_plans_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_profile_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_simcards_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_support_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_teams_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_transactions_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_users_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_vehicle_repository.dart';
export 'package:open_vts/features/admin/data/repositories/admin_vehicles_repository.dart';
export 'package:open_vts/features/admin/data/repositories/role_notifications_repository.dart';
export 'package:open_vts/features/superadmin/data/repositories/superadmin_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_drivers_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_home_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_landmarks_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_localization_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_map_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_notification_preferences_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_policy_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_profile_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_routes_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_share_track_links_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_subusers_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_support_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_transactions_repository.dart';
export 'package:open_vts/features/user/data/repositories/user_vehicles_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/features/admin/data/sources/admin_typed_api_transport.dart';
import 'package:open_vts/features/user/data/sources/user_typed_api_transport.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_typed_api_transport.dart';
import 'package:open_vts/features/admin_tools/data/repositories/api_config_repository.dart';
import 'package:open_vts/features/settings/data/repositories/app_preferences_repository.dart';
import 'package:open_vts/features/settings/data/repositories/white_label_repository.dart';
import 'package:open_vts/features/auth/data/repositories/auth_repository.dart';
import 'package:open_vts/features/auth/data/repositories/push_token_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_app_preferences_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_calendar_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_dashboard_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_devices_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_drivers_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_localization_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_logs_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_notification_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_notifications_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_payments_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_pricing_plans_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_profile_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_simcards_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_support_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_teams_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_transactions_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_users_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_vehicle_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_vehicles_repository.dart';
import 'package:open_vts/features/admin/data/repositories/role_notifications_repository.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_drivers_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_home_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_landmarks_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_localization_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_map_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_notification_preferences_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_policy_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_profile_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_routes_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_share_track_links_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_subusers_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_support_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_transactions_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicles_repository.dart';

/// Transitional repository providers for legacy routed screens.
///
/// These keep ApiClient construction out of presentation while each legacy
/// screen is migrated to feature-specific use cases/notifiers.

final adminTypedApiTransportProvider = Provider<AdminTypedApiTransport>((ref) {
  return AdminTypedApiTransport.fromDio(ref.watch(dioProvider));
});

final userTypedApiTransportProvider = Provider<UserTypedApiTransport>((ref) {
  return UserTypedApiTransport.fromDio(ref.watch(dioProvider));
});

final superadminTypedApiTransportProvider = Provider<SuperadminTypedApiTransport>((ref) {
  return SuperadminTypedApiTransport.fromDio(ref.watch(dioProvider));
});

final apiConfigRepositoryAdapterProvider = Provider<ApiConfigRepository>((ref) {
  return ApiConfigRepository(api: ref.watch(legacyApiTransportProvider));
});

final appPreferencesRepositoryAdapterProvider = Provider<AppPreferencesRepository>((ref) {
  return AppPreferencesRepository(api: ref.watch(legacyApiTransportProvider));
});

final whiteLabelRepositoryAdapterProvider = Provider<WhiteLabelRepository>((ref) {
  return WhiteLabelRepository(api: ref.watch(legacyApiTransportProvider));
});

final authRepositoryAdapterProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(legacyApiTransportProvider),
    tokenStorage: ref.watch(appContainerProvider).tokenStorage,
  );
});

final pushTokenRepositoryAdapterProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminAppPreferencesRepositoryAdapterProvider = Provider<AdminAppPreferencesRepository>((ref) {
  return AdminAppPreferencesRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminCalendarRepositoryAdapterProvider = Provider<AdminCalendarRepository>((ref) {
  return AdminCalendarRepository(api: ref.watch(adminTypedApiTransportProvider));
});

final adminDashboardRepositoryAdapterProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminDevicesRepositoryAdapterProvider = Provider<AdminDevicesRepository>((ref) {
  return AdminDevicesRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminDriversRepositoryAdapterProvider = Provider<AdminDriversRepository>((ref) {
  return AdminDriversRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminLocalizationRepositoryAdapterProvider = Provider<AdminLocalizationRepository>((ref) {
  return AdminLocalizationRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminLogsRepositoryAdapterProvider = Provider<AdminLogsRepository>((ref) {
  return AdminLogsRepository(api: ref.watch(adminTypedApiTransportProvider));
});

final adminNotificationRepositoryAdapterProvider = Provider<AdminNotificationRepository>((ref) {
  return AdminNotificationRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminNotificationsRepositoryAdapterProvider = Provider<AdminNotificationsRepository>((ref) {
  return AdminNotificationsRepository(api: ref.watch(adminTypedApiTransportProvider));
});

final adminPaymentsRepositoryAdapterProvider = Provider<AdminPaymentsRepository>((ref) {
  return AdminPaymentsRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminPricingPlansRepositoryAdapterProvider = Provider<AdminPricingPlansRepository>((ref) {
  return AdminPricingPlansRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminProfileRepositoryAdapterProvider = Provider<AdminProfileRepository>((ref) {
  return AdminProfileRepository(api: ref.watch(adminTypedApiTransportProvider));
});

final adminRepositoryAdapterProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminSimCardsRepositoryAdapterProvider = Provider<AdminSimCardsRepository>((ref) {
  return AdminSimCardsRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminSupportRepositoryAdapterProvider = Provider<AdminSupportRepository>((ref) {
  return AdminSupportRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminTeamsRepositoryAdapterProvider = Provider<AdminTeamsRepository>((ref) {
  return AdminTeamsRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminTransactionsRepositoryAdapterProvider = Provider<AdminTransactionsRepository>((ref) {
  return AdminTransactionsRepository(api: ref.watch(adminTypedApiTransportProvider));
});

final adminUsersRepositoryAdapterProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(api: ref.watch(adminTypedApiTransportProvider));
});

final adminVehicleRepositoryAdapterProvider = Provider<AdminVehicleRepository>((ref) {
  return AdminVehicleRepository(api: ref.watch(legacyApiTransportProvider));
});

final adminVehiclesRepositoryAdapterProvider = Provider<AdminVehiclesRepository>((ref) {
  return AdminVehiclesRepository(api: ref.watch(legacyApiTransportProvider));
});


final superadminRepositoryAdapterProvider = Provider<SuperadminRepository>((ref) {
  return SuperadminRepository(api: ref.watch(superadminTypedApiTransportProvider));
});

final userDriversRepositoryAdapterProvider = Provider<UserDriversRepository>((ref) {
  return UserDriversRepository(api: ref.watch(userTypedApiTransportProvider));
});

final userHomeRepositoryAdapterProvider = Provider<UserHomeRepository>((ref) {
  return UserHomeRepository(api: ref.watch(legacyApiTransportProvider));
});

final userLandmarksRepositoryAdapterProvider = Provider<UserLandmarksRepository>((ref) {
  return UserLandmarksRepository(api: ref.watch(legacyApiTransportProvider));
});

final userLocalizationRepositoryAdapterProvider = Provider<UserLocalizationRepository>((ref) {
  return UserLocalizationRepository(api: ref.watch(legacyApiTransportProvider));
});

final userMapRepositoryAdapterProvider = Provider<UserMapRepository>((ref) {
  return UserMapRepository(api: ref.watch(legacyApiTransportProvider));
});

final userNotificationPreferencesRepositoryAdapterProvider = Provider<UserNotificationPreferencesRepository>((ref) {
  return UserNotificationPreferencesRepository(api: ref.watch(legacyApiTransportProvider));
});

final userPolicyRepositoryAdapterProvider = Provider<UserPolicyRepository>((ref) {
  return UserPolicyRepository(api: ref.watch(legacyApiTransportProvider));
});

final userProfileRepositoryAdapterProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(api: ref.watch(userTypedApiTransportProvider));
});

final userRepositoryAdapterProvider = Provider<UserRepository>((ref) {
  return UserRepository(api: ref.watch(legacyApiTransportProvider));
});

final userRoutesRepositoryAdapterProvider = Provider<UserRoutesRepository>((ref) {
  return UserRoutesRepository(api: ref.watch(legacyApiTransportProvider));
});

final userShareTrackLinksRepositoryAdapterProvider = Provider<UserShareTrackLinksRepository>((ref) {
  return UserShareTrackLinksRepository(api: ref.watch(legacyApiTransportProvider));
});

final userSubUsersRepositoryAdapterProvider = Provider<UserSubUsersRepository>((ref) {
  return UserSubUsersRepository(api: ref.watch(legacyApiTransportProvider));
});

final userSupportRepositoryAdapterProvider = Provider<UserSupportRepository>((ref) {
  return UserSupportRepository(api: ref.watch(legacyApiTransportProvider));
});

final userTransactionsRepositoryAdapterProvider = Provider<UserTransactionsRepository>((ref) {
  return UserTransactionsRepository(api: ref.watch(legacyApiTransportProvider));
});

final userVehiclesRepositoryAdapterProvider = Provider<UserVehiclesRepository>((ref) {
  return UserVehiclesRepository(api: ref.watch(userTypedApiTransportProvider));
});
