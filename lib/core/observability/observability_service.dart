import 'package:open_vts/core/config/app_config.dart';

/// Single production observability boundary for the app.
///
/// Core and feature code must depend on this interface instead of depending on
/// Sentry, Crashlytics, analytics SDKs, or debug loggers directly. All context
/// passed to this service must be safe and redacted before it reaches a vendor.
abstract interface class ObservabilityService {
  Future<void> initialize(AppConfig config);

  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> context = const {},
  });

  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const {},
  });

  Future<void> setUser({String? id, String? role, String? tenantId});

  Future<void> clearUser();

  Future<void> addBreadcrumb(
    String category,
    String message, {
    Map<String, Object?> data = const {},
  });

  Future<void> recordMetric(
    String name,
    num value, {
    Map<String, Object?> tags = const {},
  });
}
