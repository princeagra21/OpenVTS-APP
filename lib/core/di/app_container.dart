import 'package:flutter/foundation.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/api/api_client.dart';
import 'package:open_vts/core/observability/observability_service.dart';
import 'package:open_vts/features/admin/data/repositories/admin_transactions_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_vehicles_repository.dart';
import 'package:open_vts/core/session/session_service.dart';
import 'package:open_vts/features/admin/data/repositories/admin_profile_repository.dart';
import 'package:open_vts/features/admin/data/repositories/admin_users_repository.dart';
import 'package:open_vts/features/auth/data/repositories/auth_repository.dart';
import 'package:open_vts/features/auth/data/repositories/push_token_repository.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_landmarks_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_notification_preferences_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_profile_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_routes_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_transactions_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicles_repository.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/storage/token_storage.dart';

/// All infrastructure instances must be created here or by a repository provider.
/// Do not create ApiClient instances in screens. Use injected repositories.
class AppContainer {
  AppContainer._({
    required this.appConfig,
    required this.tokenStorage,
    required this.sessionService,
    required this.apiClient,
    required this.authRepository,
    required this.pushNotificationsService,
    required this.userNotificationPreferencesRepository,
    required this.adminUsersRepository,
    required this.adminVehiclesRepository,
    required this.adminTransactionsRepository,
    required this.adminProfileRepository,
    required this.superadminRepository,
    required this.userVehiclesRepository,
    required this.userLandmarksRepository,
    required this.userRoutesRepository,
    required this.userTransactionsRepository,
    required this.userProfileRepository,
  });

  static AppContainer? _instance;

  static AppContainer initialize({
    AppConfig? config,
    ObservabilityService? observability,
  }) {
    final existing = _instance;
    if (existing != null) return existing;

    final appConfig = config ?? AppConfig.fromDartDefine();
    final tokenStorage = TokenStorage.defaultInstance();
    final sessionService = SessionService(tokenStorage: tokenStorage);
    final apiClient = ApiClient(
      config: appConfig,
      tokenStorage: tokenStorage,
      observability: observability,
    );

    final pushTokenRepository = PushTokenRepository(api: apiClient);
    final pushNotificationsService = PushNotificationsService.instance
      ..configure(
        api: apiClient,
        tokenStorage: tokenStorage,
        pushTokenRepository: pushTokenRepository,
      );

    final container = AppContainer._(
      appConfig: appConfig,
      tokenStorage: tokenStorage,
      sessionService: sessionService,
      apiClient: apiClient,
      authRepository: AuthRepository(
        api: apiClient,
        tokenStorage: tokenStorage,
      ),
      pushNotificationsService: pushNotificationsService,
      userNotificationPreferencesRepository:
          UserNotificationPreferencesRepository(api: apiClient),
      adminUsersRepository: AdminUsersRepository(api: apiClient),
      adminVehiclesRepository: AdminVehiclesRepository(api: apiClient),
      adminTransactionsRepository: AdminTransactionsRepository(api: apiClient),
      adminProfileRepository: AdminProfileRepository(api: apiClient),
      superadminRepository: SuperadminRepository(api: apiClient),
      userVehiclesRepository: UserVehiclesRepository(api: apiClient),
      userLandmarksRepository: UserLandmarksRepository(api: apiClient),
      userRoutesRepository: UserRoutesRepository(api: apiClient),
      userTransactionsRepository: UserTransactionsRepository(api: apiClient),
      userProfileRepository: UserProfileRepository(api: apiClient),
    );

    _instance = container;
    return container;
  }

  static AppContainer get instance {
    final container = _instance;
    if (container == null) {
      throw StateError(
        'AppContainer is not initialized. Call AppContainer.initialize() in main().',
      );
    }
    return container;
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  final AppConfig appConfig;
  final TokenStorageBase tokenStorage;
  final SessionService sessionService;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final PushNotificationsService pushNotificationsService;
  final UserNotificationPreferencesRepository
  userNotificationPreferencesRepository;
  final AdminUsersRepository adminUsersRepository;
  final AdminVehiclesRepository adminVehiclesRepository;
  final AdminTransactionsRepository adminTransactionsRepository;
  final AdminProfileRepository adminProfileRepository;
  final SuperadminRepository superadminRepository;
  final UserVehiclesRepository userVehiclesRepository;
  final UserLandmarksRepository userLandmarksRepository;
  final UserRoutesRepository userRoutesRepository;
  final UserTransactionsRepository userTransactionsRepository;
  final UserProfileRepository userProfileRepository;
}
