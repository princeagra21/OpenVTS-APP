import 'package:flutter/foundation.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/session/session_service.dart';
import 'package:open_vts/core/repositories/admin_profile_repository.dart';
import 'package:open_vts/core/repositories/admin_users_repository.dart';
import 'package:open_vts/core/repositories/auth_repository.dart';
import 'package:open_vts/core/repositories/push_token_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/repositories/user_notification_preferences_repository.dart';
import 'package:open_vts/core/repositories/user_profile_repository.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/storage/token_storage.dart';

/// All infrastructure instances must be created here or by a repository provider.
/// Do not create ApiClient instances in screens. Use AppContainer.instance.apiClient or injected repositories.
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
    required this.adminProfileRepository,
    required this.superadminRepository,
    required this.userProfileRepository,
  });

  static AppContainer? _instance;

  static AppContainer initialize() {
    final existing = _instance;
    if (existing != null) return existing;

    final appConfig = AppConfig.fromDartDefine();
    final tokenStorage = TokenStorage.defaultInstance();
    final sessionService = SessionService(tokenStorage: tokenStorage);
    final apiClient = ApiClient(config: appConfig, tokenStorage: tokenStorage);

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
      adminProfileRepository: AdminProfileRepository(api: apiClient),
      superadminRepository: SuperadminRepository(api: apiClient),
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
  final AdminProfileRepository adminProfileRepository;
  final SuperadminRepository superadminRepository;
  final UserProfileRepository userProfileRepository;
}
