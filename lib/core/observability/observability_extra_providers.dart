import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/diagnostics/diagnostics_providers.dart';
import 'package:open_vts/core/observability/analytics_service.dart';
import 'package:open_vts/core/observability/diagnostics_service.dart';
import 'package:open_vts/core/observability/observability_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(observabilityServiceProvider));
});

final diagnosticsServiceProvider = Provider<DiagnosticsService>((ref) {
  return DiagnosticsService(
    apiDiagnostics: ref.watch(apiDiagnosticsProvider),
    socketDiagnostics: ref.watch(socketDiagnosticsProvider),
    mapDiagnostics: ref.watch(mapPerformanceDiagnosticsProvider),
    observability: ref.watch(observabilityServiceProvider),
  );
});
