import 'package:open_vts/core/config/api_base_url_config.dart';

class AppConfig {
  final AppEnvironment environment;
  final String baseUrl;
  final String socketUrl;
  final bool enableNetworkLogs;
  final bool enableCrashReporting;
  final bool enablePerformanceDiagnostics;
  final bool enableObservability;
  final bool enableSentry;
  final bool enableCrashlytics;
  final String sentryDsn;
  final double sentryTracesSampleRate;
  final String releaseName;

  const AppConfig({
    required this.environment,
    required this.baseUrl,
    String? socketUrl,
    this.enableNetworkLogs = true,
    this.enableCrashReporting = false,
    this.enablePerformanceDiagnostics = true,
    this.enableObservability = true,
    this.enableSentry = false,
    this.enableCrashlytics = false,
    this.sentryDsn = '',
    this.sentryTracesSampleRate = 0.0,
    this.releaseName = 'open-vts@unknown',
  }) : socketUrl = socketUrl ?? baseUrl;

  bool get isProduction => environment == AppEnvironment.prod;

  AppConfig copyWith({
    AppEnvironment? environment,
    String? baseUrl,
    String? socketUrl,
    bool? enableNetworkLogs,
    bool? enableCrashReporting,
    bool? enablePerformanceDiagnostics,
    bool? enableObservability,
    bool? enableSentry,
    bool? enableCrashlytics,
    String? sentryDsn,
    double? sentryTracesSampleRate,
    String? releaseName,
  }) {
    return AppConfig(
      environment: environment ?? this.environment,
      baseUrl: baseUrl ?? this.baseUrl,
      socketUrl: socketUrl ?? this.socketUrl,
      enableNetworkLogs: enableNetworkLogs ?? this.enableNetworkLogs,
      enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
      enablePerformanceDiagnostics: enablePerformanceDiagnostics ?? this.enablePerformanceDiagnostics,
      enableObservability: enableObservability ?? this.enableObservability,
      enableSentry: enableSentry ?? this.enableSentry,
      enableCrashlytics: enableCrashlytics ?? this.enableCrashlytics,
      sentryDsn: sentryDsn ?? this.sentryDsn,
      sentryTracesSampleRate: sentryTracesSampleRate ?? this.sentryTracesSampleRate,
      releaseName: releaseName ?? this.releaseName,
    );
  }

  /// Selects an environment based on `--dart-define=APP_ENV=dev|staging|prod`.
  /// Base URL uses the runtime config service, which falls back to the
  /// `--dart-define=API_BASE_URL=https://...` value.
  static AppConfig fromDartDefine() {
    const envRaw = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const socketRaw = String.fromEnvironment('SOCKET_BASE_URL', defaultValue: '');
    const enableNetworkLogsRaw = String.fromEnvironment('ENABLE_NETWORK_LOGS', defaultValue: '');
    const enableCrashReportingRaw = String.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: '');
    const enablePerformanceDiagnosticsRaw = String.fromEnvironment('ENABLE_PERFORMANCE_DIAGNOSTICS', defaultValue: '');
    const enableObservabilityRaw = String.fromEnvironment('ENABLE_OBSERVABILITY', defaultValue: '');
    const enableSentryRaw = String.fromEnvironment('ENABLE_SENTRY', defaultValue: '');
    const enableCrashlyticsRaw = String.fromEnvironment('ENABLE_CRASHLYTICS', defaultValue: '');
    const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    const sentryTraceSampleRateRaw = String.fromEnvironment('SENTRY_TRACES_SAMPLE_RATE', defaultValue: '');
    const releaseName = String.fromEnvironment('RELEASE_NAME', defaultValue: 'open-vts@unknown');

    final env = AppEnvironmentX.tryParse(envRaw) ?? AppEnvironment.dev;
    final baseUrl = ApiBaseUrlConfig.instance.effectiveBaseUrl;
    final enableCrashReporting = enableCrashReportingRaw.trim().isEmpty
        ? env == AppEnvironment.prod
        : enableCrashReportingRaw.toLowerCase() == 'true';
    final enableObservability = enableObservabilityRaw.trim().isEmpty
        ? env != AppEnvironment.dev || enableCrashReporting
        : enableObservabilityRaw.toLowerCase() == 'true';
    final sentryTraceSampleRate = double.tryParse(sentryTraceSampleRateRaw.trim()) ??
        (env == AppEnvironment.prod ? 0.05 : 0.0);

    return AppConfig(
      environment: env,
      baseUrl: baseUrl,
      socketUrl: socketRaw.trim().isEmpty ? baseUrl : socketRaw,
      enableNetworkLogs: enableNetworkLogsRaw.trim().isEmpty
          ? env != AppEnvironment.prod
          : enableNetworkLogsRaw.toLowerCase() == 'true',
      enableCrashReporting: enableCrashReporting,
      enablePerformanceDiagnostics: enablePerformanceDiagnosticsRaw.trim().isEmpty
          ? env != AppEnvironment.prod
          : enablePerformanceDiagnosticsRaw.toLowerCase() == 'true',
      enableObservability: enableObservability,
      enableSentry: enableSentryRaw.trim().isEmpty
          ? sentryDsn.trim().isNotEmpty
          : enableSentryRaw.toLowerCase() == 'true',
      enableCrashlytics: enableCrashlyticsRaw.trim().isEmpty
          ? enableCrashReporting
          : enableCrashlyticsRaw.toLowerCase() == 'true',
      sentryDsn: sentryDsn,
      sentryTracesSampleRate: sentryTraceSampleRate,
      releaseName: releaseName,
    );
  }
}

enum AppEnvironment { dev, staging, prod }

extension AppEnvironmentX on AppEnvironment {
  static AppEnvironment? tryParse(String value) {
    final v = value.trim().toLowerCase();
    return switch (v) {
      'dev' || 'development' => AppEnvironment.dev,
      'staging' => AppEnvironment.staging,
      'prod' || 'production' => AppEnvironment.prod,
      _ => null,
    };
  }
}
