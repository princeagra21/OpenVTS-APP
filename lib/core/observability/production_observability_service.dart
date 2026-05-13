import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/debug/app_logger.dart';
import 'package:open_vts/core/observability/observability_service.dart';
import 'package:open_vts/core/security/token_redactor.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Production adapter for Sentry + Firebase Crashlytics.
///
/// The adapter is intentionally defensive: a missing native Firebase config,
/// empty Sentry DSN, or SDK initialization failure must never prevent the app
/// from launching. Failures fall back to the redacted logger in development.
class ProductionObservabilityService implements ObservabilityService {
  ProductionObservabilityService({TokenRedactor redactor = const TokenRedactor()})
      : _redactor = redactor;

  final TokenRedactor _redactor;
  bool _sentryEnabled = false;
  bool _crashlyticsEnabled = false;

  @override
  Future<void> initialize(AppConfig config) async {
    _sentryEnabled = false;
    _crashlyticsEnabled = false;

    if (config.enableSentry && config.sentryDsn.trim().isNotEmpty) {
      try {
        await SentryFlutter.init((options) {
          options.dsn = config.sentryDsn.trim();
          options.environment = config.environment.name;
          options.release = config.releaseName;
          options.tracesSampleRate = config.sentryTracesSampleRate;
          options.sendDefaultPii = false;
          options.attachScreenshot = false;
          options.attachViewHierarchy = false;
        });
        _sentryEnabled = true;
      } catch (error, stackTrace) {
        AppLogger.error(
          'sentry_initialization_failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (config.enableCrashlytics) {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        _crashlyticsEnabled = true;
      } catch (error, stackTrace) {
        AppLogger.error(
          'crashlytics_initialization_failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    await addBreadcrumb('app', 'observability_initialized', data: <String, Object?>{
      'environment': config.environment.name,
      'sentry': _sentryEnabled,
      'crashlytics': _crashlyticsEnabled,
    });
  }

  @override
  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> context = const {},
  }) async {
    final safeContext = _safeContext(context);
    if (_sentryEnabled) {
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
    if (_crashlyticsEnabled) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'OpenVTS captured exception',
        information: safeContext.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .toList(growable: false),
      );
    }
    AppLogger.error(
      'captured_exception',
      error: error,
      stackTrace: stackTrace,
      context: safeContext,
    );
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const {},
  }) async {
    final safeMessage = _redactor.redact(message);
    final safeContext = _safeContext(context);
    if (_sentryEnabled) {
      await Sentry.captureMessage(safeMessage);
    }
    if (_crashlyticsEnabled) {
      FirebaseCrashlytics.instance.log('$safeMessage $safeContext');
    }
    AppLogger.info(safeMessage, context: safeContext);
  }

  @override
  Future<void> setUser({String? id, String? role, String? tenantId}) async {
    final safeId = _redactor.redact(id);
    final safeRole = _redactor.redact(role);
    final safeTenantId = _redactor.redact(tenantId);
    if (_sentryEnabled) {
      await Sentry.configureScope((scope) {
        scope.setUser(
          SentryUser(
            id: safeId.isEmpty ? null : safeId,
            data: <String, String>{
              if (safeRole.isNotEmpty) 'role': safeRole,
              if (safeTenantId.isNotEmpty) 'tenantId': safeTenantId,
            },
          ),
        );
      });
    }
    if (_crashlyticsEnabled) {
      await FirebaseCrashlytics.instance.setUserIdentifier(safeId);
      if (safeRole.isNotEmpty) {
        await FirebaseCrashlytics.instance.setCustomKey('role', safeRole);
      }
      if (safeTenantId.isNotEmpty) {
        await FirebaseCrashlytics.instance.setCustomKey('tenantId', safeTenantId);
      }
    }
  }

  @override
  Future<void> clearUser() async {
    if (_sentryEnabled) {
      await Sentry.configureScope((scope) => scope.setUser(null));
    }
    if (_crashlyticsEnabled) {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
      await FirebaseCrashlytics.instance.setCustomKey('role', '');
      await FirebaseCrashlytics.instance.setCustomKey('tenantId', '');
    }
  }

  @override
  Future<void> addBreadcrumb(
    String category,
    String message, {
    Map<String, Object?> data = const {},
  }) async {
    final safeData = _safeContext(data);
    final safeMessage = _redactor.redact(message);
    if (_sentryEnabled) {
      await Sentry.addBreadcrumb(
        Breadcrumb(
          category: _redactor.redact(category),
          message: safeMessage,
          data: safeData,
        ),
      );
    }
    if (_crashlyticsEnabled) {
      FirebaseCrashlytics.instance.log('${_redactor.redact(category)}:$safeMessage $safeData');
    }
    if (kDebugMode) {
      AppLogger.event('breadcrumb_${_redactor.redact(category)}', context: <String, Object?>{
        'message': safeMessage,
        ...safeData,
      });
    }
  }

  @override
  Future<void> recordMetric(
    String name,
    num value, {
    Map<String, Object?> tags = const {},
  }) async {
    final safeTags = _safeContext(tags);
    final safeName = _redactor.redact(name);
    // Sentry/Crashlytics metric APIs vary by SDK version. Recording metrics as
    // breadcrumbs keeps this adapter stable while still surfacing operational
    // signals in production traces and crash sessions.
    await addBreadcrumb('metric', safeName, data: <String, Object?>{
      'value': value,
      ...safeTags,
    });
  }

  Map<String, Object?> _safeContext(Map<String, Object?> context) {
    final redacted = _redactor.redactMap(context);
    return redacted.map((key, value) => MapEntry(_redactor.redact(key), _safeValue(value)));
  }

  Object? _safeValue(Object? value) {
    if (value is String) return _redactor.redact(value);
    if (value is Map<String, Object?>) return _safeContext(value);
    if (value is Iterable) {
      return value.map((item) => item is String ? _redactor.redact(item) : item).toList(growable: false);
    }
    return value;
  }
}
