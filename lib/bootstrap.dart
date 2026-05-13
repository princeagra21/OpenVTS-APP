import 'dart:async';
import 'dart:ui';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/app.dart';
import 'package:open_vts/core/config/api_base_url_config.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/config/app_config_validator.dart';
import 'package:open_vts/core/debug/app_logger.dart';
import 'package:open_vts/core/di/app_container.dart';
import 'package:open_vts/core/observability/observability_provider.dart';
import 'package:open_vts/core/observability/observability_service.dart';
import 'package:open_vts/core/observability/production_observability_service.dart';
import 'package:open_vts/core/router/app_router.dart';
import 'package:open_vts/core/storage/cache_storage.dart';
import 'package:open_vts/core/theme/theme_controller.dart';

Future<void> bootstrapOpenVts() async {
  final observability = ProductionObservabilityService();

  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await ApiBaseUrlConfig.instance.load();
    final config = AppConfig.fromDartDefine();
    final configValidation = const AppConfigValidator().validate(config);
    if (configValidation.isFailure) {
      throw StateError(
        'Invalid production configuration: ${configValidation.errorOrNull!.message}',
      );
    }
    await observability.initialize(config);
    _installGlobalErrorHandlers(observability);
    await observability.addBreadcrumb('app', 'app_started', data: <String, Object?>{
      'environment': config.environment.name,
      'release': config.releaseName,
    });
    await observability.recordMetric('app.started', 1, tags: <String, Object?>{
      'environment': config.environment.name,
    });

    await initCacheStorage();
    final appContainer = AppContainer.initialize(
      config: config,
      observability: observability,
    );
    await themeController.loadTheme();

    final initialLocation = await AppRouter.resolveInitialLocation(
      tokenStorage: appContainer.tokenStorage,
    );
    const forceDevicePreview = bool.fromEnvironment(
      'DEVICE_PREVIEW',
      defaultValue: false,
    );
    final enableDevicePreview = forceDevicePreview && !kReleaseMode;

    if (kDebugMode) {
      AppLogger.debug('[AuthBootstrap] initialLocation=$initialLocation');
      AppLogger.debug('[Bootstrap] devicePreview=$enableDevicePreview');
    }

    final appRouter = AppRouter.build(
      initialLocation: initialLocation,
      tokenStorage: appContainer.tokenStorage,
    );

    runApp(
      ProviderScope(
        overrides: [
          observabilityConfigProvider.overrideWithValue(config),
          observabilityServiceProvider.overrideWithValue(observability),
        ],
        child: enableDevicePreview
            ? DevicePreview(
                enabled: true,
                builder: (_) => FleetStackApp(
                  router: appRouter,
                  enableDevicePreview: enableDevicePreview,
                ),
              )
            : FleetStackApp(
                router: appRouter,
                enableDevicePreview: enableDevicePreview,
              ),
      ),
    );
  }, (error, stackTrace) async {
    await observability.captureException(
      error,
      stackTrace,
      context: const <String, Object?>{'source': 'runZonedGuarded'},
    );
  });
}

void _installGlobalErrorHandlers(ObservabilityService observability) {
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
      AppLogger.debug('FLUTTER_ERROR: ${details.exceptionAsString()}');
      debugPrintStack(stackTrace: details.stack);
    }
    unawaited(
      observability.captureException(
        details.exception,
        details.stack ?? StackTrace.current,
        context: <String, Object?>{
          'source': 'FlutterError.onError',
          'library': details.library,
          'context': details.context?.toDescription(),
        },
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    if (kDebugMode) {
      AppLogger.debug('PLATFORM_ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    unawaited(
      observability.captureException(
        error,
        stackTrace,
        context: const <String, Object?>{'source': 'PlatformDispatcher.onError'},
      ),
    );
    return true;
  };
}
