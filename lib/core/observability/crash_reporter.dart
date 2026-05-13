import 'package:open_vts/core/observability/observability_service.dart';

abstract interface class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?> context = const {},
    bool fatal = false,
  });

  Future<void> setUserContext({
    required String userId,
    required String role,
    String? tenantId,
  });

  Future<void> clearUserContext();
}

class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> clearUserContext() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?> context = const {},
    bool fatal = false,
  }) async {}

  @override
  Future<void> setUserContext({
    required String userId,
    required String role,
    String? tenantId,
  }) async {}
}

class ObservabilityCrashReporter implements CrashReporter {
  const ObservabilityCrashReporter(this._observability);

  final ObservabilityService _observability;

  @override
  Future<void> clearUserContext() => _observability.clearUser();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?> context = const {},
    bool fatal = false,
  }) {
    return _observability.captureException(
      error,
      stackTrace,
      context: <String, Object?>{
        ...context,
        if (reason != null) 'reason': reason,
        'fatal': fatal,
      },
    );
  }

  @override
  Future<void> setUserContext({
    required String userId,
    required String role,
    String? tenantId,
  }) {
    return _observability.setUser(id: userId, role: role, tenantId: tenantId);
  }
}

typedef CrashRecordError = Future<void> Function(
  Object error,
  StackTrace stackTrace, {
  String? reason,
  Map<String, Object?> context,
  bool fatal,
});

typedef CrashSetUser = Future<void> Function({
  required String userId,
  required String role,
  String? tenantId,
});

typedef CrashClearUser = Future<void> Function();

/// Adapter prepared for Firebase Crashlytics, Sentry, or another crash backend.
///
/// Prefer [ObservabilityCrashReporter] for production app wiring. This callback
/// adapter remains useful in tests or platform-specific integration layers.
class CallbackCrashReporter implements CrashReporter {
  const CallbackCrashReporter({
    required CrashRecordError recordErrorCallback,
    required CrashSetUser setUserCallback,
    required CrashClearUser clearUserCallback,
  })  : _recordErrorCallback = recordErrorCallback,
        _setUserCallback = setUserCallback,
        _clearUserCallback = clearUserCallback;

  final CrashRecordError _recordErrorCallback;
  final CrashSetUser _setUserCallback;
  final CrashClearUser _clearUserCallback;

  @override
  Future<void> clearUserContext() => _clearUserCallback();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, Object?> context = const {},
    bool fatal = false,
  }) {
    return _recordErrorCallback(
      error,
      stackTrace,
      reason: reason,
      context: context,
      fatal: fatal,
    );
  }

  @override
  Future<void> setUserContext({
    required String userId,
    required String role,
    String? tenantId,
  }) {
    return _setUserCallback(userId: userId, role: role, tenantId: tenantId);
  }
}
