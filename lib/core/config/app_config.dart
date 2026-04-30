import 'package:fleet_stack/core/config/api_base_url_config.dart';

class AppConfig {
  final AppEnvironment environment;
  final String baseUrl;

  const AppConfig({required this.environment, required this.baseUrl});

  /// Selects an environment based on `--dart-define=APP_ENV=dev|staging|prod`.
  /// Base URL uses the runtime config service, which falls back to the
  /// `--dart-define=API_BASE_URL=https://...` value.
  static AppConfig fromDartDefine() {
    const envRaw = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

    final env = AppEnvironmentX.tryParse(envRaw) ?? AppEnvironment.dev;

    return AppConfig(
      environment: env,
      baseUrl: ApiBaseUrlConfig.instance.effectiveBaseUrl,
    );
  }
}

enum AppEnvironment { dev, staging, prod }

extension AppEnvironmentX on AppEnvironment {
  static AppEnvironment? tryParse(String value) {
    final v = value.trim().toLowerCase();
    return switch (v) {
      'dev' => AppEnvironment.dev,
      'staging' => AppEnvironment.staging,
      'prod' => AppEnvironment.prod,
      _ => null,
    };
  }
}
