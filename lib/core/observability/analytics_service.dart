import 'package:open_vts/core/observability/observability_service.dart';

class AnalyticsService {
  const AnalyticsService(this._observability);

  final ObservabilityService _observability;

  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) {
    return _observability.addBreadcrumb('analytics', event, data: properties);
  }

  Future<void> metric(
    String name,
    num value, {
    Map<String, Object?> tags = const {},
  }) {
    return _observability.recordMetric(name, value, tags: tags);
  }
}
