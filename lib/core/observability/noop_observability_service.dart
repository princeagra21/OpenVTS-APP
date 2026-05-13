import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/observability/observability_service.dart';

class NoopObservabilityService implements ObservabilityService {
  const NoopObservabilityService();

  @override
  Future<void> initialize(AppConfig config) async {}

  @override
  Future<void> captureException(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> context = const {},
  }) async {}

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const {},
  }) async {}

  @override
  Future<void> setUser({String? id, String? role, String? tenantId}) async {}

  @override
  Future<void> clearUser() async {}

  @override
  Future<void> addBreadcrumb(
    String category,
    String message, {
    Map<String, Object?> data = const {},
  }) async {}

  @override
  Future<void> recordMetric(
    String name,
    num value, {
    Map<String, Object?> tags = const {},
  }) async {}
}
