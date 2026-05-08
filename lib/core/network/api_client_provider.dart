import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/storage/token_storage.dart';

class ApiClientProvider {
  const ApiClientProvider._();

  static ApiClient create({AppConfig? config, TokenStorageBase? tokenStorage}) {
    final resolvedTokenStorage =
        tokenStorage ?? AppContainer.instance.tokenStorage;
    return ApiClient(
      config: config ?? AppConfig.fromDartDefine(),
      tokenStorage: resolvedTokenStorage,
    );
  }
}
