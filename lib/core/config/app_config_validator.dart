import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';

class AppConfigValidator {
  const AppConfigValidator();

  Result<AppConfig, AppError> validate(AppConfig config) {
    final baseResult = _validateUrl(config.baseUrl, label: 'API base URL');
    if (baseResult.isFailure) return Result.failure(baseResult.errorOrNull!);

    final socketResult = _validateUrl(config.socketUrl, label: 'Socket URL');
    if (socketResult.isFailure) return Result.failure(socketResult.errorOrNull!);

    if (config.sentryTracesSampleRate < 0 || config.sentryTracesSampleRate > 1) {
      return const Result.failure(
        ValidationError('Sentry traces sample rate must be between 0 and 1'),
      );
    }

    if (config.releaseName.trim().isEmpty) {
      return const Result.failure(ValidationError('Release name is required'));
    }

    if (config.environment == AppEnvironment.prod) {
      final baseUri = Uri.parse(config.baseUrl.trim());
      final socketUri = Uri.parse(config.socketUrl.trim());

      for (final entry in <String, Uri>{
        'Production API base URL': baseUri,
        'Production socket URL': socketUri,
      }.entries) {
        if (entry.value.scheme.toLowerCase() != 'https') {
          return Result.failure(ValidationError('${entry.key} must use HTTPS'));
        }
        final hostError = _productionHostError(entry.key, entry.value.host);
        if (hostError != null) return Result.failure(hostError);
      }

      if (config.enableNetworkLogs) {
        return const Result.failure(
          ValidationError('Production network logs must be disabled'),
        );
      }
      if (config.enablePerformanceDiagnostics) {
        return const Result.failure(
          ValidationError('Production debug performance diagnostics must be disabled'),
        );
      }
      if (!config.enableObservability) {
        return const Result.failure(
          ValidationError('Production observability must be enabled'),
        );
      }
      if (!config.enableCrashReporting) {
        return const Result.failure(
          ValidationError('Production crash reporting must be enabled'),
        );
      }
      if (!config.enableSentry && !config.enableCrashlytics) {
        return const Result.failure(
          ValidationError('Production must enable at least one crash backend'),
        );
      }
      if (config.enableSentry && config.sentryDsn.trim().isEmpty) {
        return const Result.failure(
          ValidationError('Sentry DSN is required when Sentry is enabled'),
        );
      }
    }
    return Result.success(config);
  }

  Result<Uri, AppError> _validateUrl(String raw, {required String label}) {
    final value = raw.trim();
    if (value.isEmpty) {
      return Result.failure(ValidationError('$label is required'));
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return Result.failure(ValidationError('Invalid $label: $value'));
    }
    if (uri.hasFragment) {
      return Result.failure(ValidationError('$label must not include a URL fragment'));
    }
    if (uri.userInfo.trim().isNotEmpty) {
      return Result.failure(ValidationError('$label must not include credentials'));
    }
    return Result.success(uri);
  }

  ValidationError? _productionHostError(String label, String host) {
    final normalized = host.trim().toLowerCase();
    if (normalized.isEmpty) {
      return ValidationError('$label host is required');
    }
    final blockedHosts = <String>{
      'localhost',
      '127.0.0.1',
      '0.0.0.0',
      '::1',
      '10.0.2.2',
      '10.0.3.2',
    };
    if (blockedHosts.contains(normalized) || normalized.endsWith('.local')) {
      return ValidationError('$label cannot point to localhost or emulator host');
    }
    if (normalized.contains('staging') || normalized.contains('dev')) {
      return ValidationError('$label cannot point to dev/staging host');
    }
    if (_isPrivateIpv4(normalized)) {
      return ValidationError('$label cannot point to a private network host');
    }
    return null;
  }

  bool _isPrivateIpv4(String host) {
    final parts = host.split('.').map(int.tryParse).toList(growable: false);
    if (parts.length != 4 || parts.any((part) => part == null || part < 0 || part > 255)) {
      return false;
    }
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        a == 127 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }
}
