import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/api/api_client.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';
import 'package:open_vts/core/di/app_container.dart';
import 'package:open_vts/core/socket/socket_service.dart';
import 'package:open_vts/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:open_vts/core/diagnostics/diagnostics_providers.dart';
import 'package:open_vts/core/network/diagnostic_dio_interceptor.dart';
import 'package:open_vts/core/observability/observability_provider.dart';

/// Shared dependency providers.
///
/// Existing production repositories still use [AppContainer], while new
/// feature-first code can depend on these Riverpod providers. This keeps DI
/// centralized and prevents screens from creating API/socket/storage objects.
final appContainerProvider = Provider<AppContainer>((ref) {
  return AppContainer.instance;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(appContainerProvider).apiClient;
});

/// Narrow compatibility transport for legacy repositories that have not yet
/// been migrated to Retrofit. Do not inject [ApiClient] into feature code.
final legacyApiTransportProvider = Provider<LegacyApiTransport>((ref) {
  return ref.watch(apiClientProvider);
});


final dioProvider = Provider<Dio>((ref) {
  final container = ref.watch(appContainerProvider);
  final dio = container.apiClient.dio;
  final hasDiagnostics = dio.interceptors.any((interceptor) => interceptor is DiagnosticDioInterceptor);
  if (container.appConfig.enablePerformanceDiagnostics && !hasDiagnostics) {
    dio.interceptors.add(
      DiagnosticDioInterceptor(
        diagnostics: ref.watch(apiDiagnosticsProvider),
        observability: ref.watch(observabilityServiceProvider),
      ),
    );
  }
  return dio;
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage(
    tokenStorage: ref.watch(appContainerProvider).tokenStorage,
  );
});

/// Loads the current access token from secure storage.
///
/// Do not rely on [SecureStorage.getCachedToken] during app startup because a
/// fresh wrapper has no in-memory cache yet. Socket connections must wait for
/// this provider to resolve before connecting.
final accessTokenProvider = FutureProvider<String?>((ref) async {
  return ref.watch(secureStorageProvider).getAccessToken();
});

final socketServiceProvider = FutureProvider<SocketService>((ref) async {
  final token = await ref.watch(accessTokenProvider.future) ?? '';
  final service = SocketService(
    token: token,
    diagnostics: ref.watch(socketDiagnosticsProvider),
    observability: ref.watch(observabilityServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

