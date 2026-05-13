import 'package:flutter/foundation.dart';
import 'package:open_vts/core/di/app_container.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/api/api_client.dart';
import 'package:open_vts/core/storage/token_storage.dart';

class ApiClientProvider {
  const ApiClientProvider._();

  /// Do not create ApiClient instances in screens. Use AppContainer.instance.apiClient or injected repositories.
  static ApiClient shared() => AppContainer.instance.apiClient;

  @Deprecated(
    'Use shared() in app code. Use createForTesting() for isolated clients.',
  )
  static ApiClient create({AppConfig? config, TokenStorageBase? tokenStorage}) {
    if (config == null && tokenStorage == null) {
      return shared();
    }

    return createForTesting(
      config: config ?? AppConfig.fromDartDefine(),
      tokenStorage: tokenStorage ?? AppContainer.instance.tokenStorage,
    );
  }

  @visibleForTesting
  static ApiClient createForTesting({
    required AppConfig config,
    required TokenStorageBase tokenStorage,
  }) {
    return ApiClient(config: config, tokenStorage: tokenStorage);
  }
}
