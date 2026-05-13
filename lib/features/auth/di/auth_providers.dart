import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/database/database_providers.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/socket/socket_providers.dart';
import 'package:open_vts/features/auth/data/mappers/auth_mapper.dart';
import 'package:open_vts/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:open_vts/features/auth/data/sources/auth_retrofit_service.dart';
import 'package:open_vts/features/auth/domain/repositories/auth_repository.dart';
import 'package:open_vts/features/auth/domain/use_cases/forgot_password_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/login_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:open_vts/features/auth/domain/use_cases/restore_session_use_case.dart';

final authRetrofitServiceProvider = Provider<AuthRetrofitService>((ref) {
  return AuthRetrofitService(ref.watch(dioProvider));
});

final authMapperProvider = Provider<AuthMapper>((ref) {
  return const AuthMapper();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(authRetrofitServiceProvider),
    storage: ref.watch(secureStorageProvider),
    mapper: ref.watch(authMapperProvider),
    cacheDatabase: ref.watch(appDatabaseProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final authSessionCleanupProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(accessTokenProvider);
    ref.invalidate(socketServiceProvider);
    ref.invalidate(coreSocketAccessTokenProvider);
    ref.invalidate(coreSocketServiceProvider);
  };
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  return ForgotPasswordUseCase(ref.watch(authRepositoryProvider));
});

class AuthBaseUrlUpdater {
  const AuthBaseUrlUpdater(this._update);

  final void Function(String baseUrl) _update;

  void updateBaseUrl(String baseUrl) => _update(baseUrl);
}

final authBaseUrlUpdaterProvider = Provider<AuthBaseUrlUpdater>((ref) {
  return AuthBaseUrlUpdater(ref.watch(apiClientProvider).updateBaseUrl);
});

final authPushNotificationsServiceProvider = Provider<PushNotificationsService>((ref) {
  return ref.watch(appContainerProvider).pushNotificationsService;
});
