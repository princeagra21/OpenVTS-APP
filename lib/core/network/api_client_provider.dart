import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/storage/token_storage.dart';

class ApiClientProvider {
  const ApiClientProvider._();

  static ApiClient create({
    AppConfig? config,
    TokenStorageBase? tokenStorage,
  }) {
    return ApiClient(
      config: config ?? AppConfig.fromDartDefine(),
      tokenStorage: tokenStorage ?? TokenStorage.defaultInstance(),
    );
  }
}
