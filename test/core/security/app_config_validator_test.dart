import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/config/app_config_validator.dart';

void main() {
  const validator = AppConfigValidator();

  test('rejects production http base url', () {
    final result = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'http://example.com',
        socketUrl: 'https://socket.example.com',
        enableNetworkLogs: false,
        enableCrashReporting: true,
        enablePerformanceDiagnostics: false,
        enableObservability: true,
      ),
    );

    expect(result.isFailure, isTrue);
  });

  test('rejects localhost and emulator urls in production', () {
    final localhost = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'https://localhost/api',
        socketUrl: 'https://socket.example.com',
        enableNetworkLogs: false,
        enableCrashReporting: true,
        enablePerformanceDiagnostics: false,
        enableObservability: true,
      ),
    );
    final emulator = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'https://api.example.com',
        socketUrl: 'https://10.0.2.2/socket',
        enableNetworkLogs: false,
        enableCrashReporting: true,
        enablePerformanceDiagnostics: false,
        enableObservability: true,
      ),
    );

    expect(localhost.isFailure, isTrue);
    expect(emulator.isFailure, isTrue);
  });

  test('rejects production network logs and diagnostics', () {
    final logs = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'https://api.openvts.example',
        socketUrl: 'https://socket.openvts.example',
        enableNetworkLogs: true,
        enableCrashReporting: true,
        enablePerformanceDiagnostics: false,
        enableObservability: true,
      ),
    );
    final diagnostics = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'https://api.openvts.example',
        socketUrl: 'https://socket.openvts.example',
        enableNetworkLogs: false,
        enableCrashReporting: true,
        enablePerformanceDiagnostics: true,
        enableObservability: true,
      ),
    );

    expect(logs.isFailure, isTrue);
    expect(diagnostics.isFailure, isTrue);
  });

  test('rejects production without crash reporting or observability', () {
    final noCrashReporting = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'https://api.openvts.example',
        socketUrl: 'https://socket.openvts.example',
        enableNetworkLogs: false,
        enableCrashReporting: false,
        enablePerformanceDiagnostics: false,
        enableObservability: true,
      ),
    );
    final noObservability = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'https://api.openvts.example',
        socketUrl: 'https://socket.openvts.example',
        enableNetworkLogs: false,
        enableCrashReporting: true,
        enablePerformanceDiagnostics: false,
        enableObservability: false,
      ),
    );

    expect(noCrashReporting.isFailure, isTrue);
    expect(noObservability.isFailure, isTrue);
  });


  test('rejects production without a crash backend', () {
    final result = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'https://api.openvts.example',
        socketUrl: 'https://socket.openvts.example',
        enableNetworkLogs: false,
        enableCrashReporting: true,
        enablePerformanceDiagnostics: false,
        enableObservability: true,
        enableSentry: false,
        enableCrashlytics: false,
      ),
    );

    expect(result.isFailure, isTrue);
  });

  test('accepts production https urls with safe production flags', () {
    final result = validator.validate(
      const AppConfig(
        environment: AppEnvironment.prod,
        baseUrl: 'https://api.openvts.example',
        socketUrl: 'https://socket.openvts.example',
        enableNetworkLogs: false,
        enableCrashReporting: true,
        enablePerformanceDiagnostics: false,
        enableObservability: true,
        enableCrashlytics: true,
      ),
    );

    expect(result.isSuccess, isTrue);
  });
}
