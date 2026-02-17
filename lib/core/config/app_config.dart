class AppConfig {
  final AppEnvironment environment;
  final String baseUrl;

  const AppConfig({required this.environment, required this.baseUrl});

  /// Selects an environment based on `--dart-define=APP_ENV=dev|staging|prod`.
  /// Optionally override base URL with `--dart-define=API_BASE_URL=https://...`.
  static AppConfig fromDartDefine() {
    const envRaw = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const overrideBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    final env = AppEnvironmentX.tryParse(envRaw) ?? AppEnvironment.dev;

    // TODO: Set real URLs for your environments.
    final defaultBaseUrl = switch (env) {
      AppEnvironment.dev => '',
      AppEnvironment.staging => '',
      AppEnvironment.prod => '',
    };

    return AppConfig(
      environment: env,
      baseUrl: overrideBaseUrl.isNotEmpty ? overrideBaseUrl : defaultBaseUrl,
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
