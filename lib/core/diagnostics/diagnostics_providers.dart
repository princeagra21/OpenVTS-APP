import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/diagnostics/api_diagnostics.dart';
import 'package:open_vts/core/diagnostics/map_performance_diagnostics.dart';
import 'package:open_vts/core/diagnostics/socket_diagnostics.dart';
import 'package:open_vts/core/observability/crash_reporter.dart';
import 'package:open_vts/core/observability/observability_provider.dart';

final apiDiagnosticsProvider = Provider<ApiDiagnostics>((ref) {
  return ApiDiagnostics();
});

final socketDiagnosticsProvider = Provider<SocketDiagnostics>((ref) {
  return SocketDiagnostics(
    observability: ref.watch(observabilityServiceProvider),
  );
});

final mapPerformanceDiagnosticsProvider = Provider<MapPerformanceDiagnostics>((ref) {
  return MapPerformanceDiagnostics(
    observability: ref.watch(observabilityServiceProvider),
  );
});

final crashReporterProvider = Provider<CrashReporter>((ref) {
  return ObservabilityCrashReporter(ref.watch(observabilityServiceProvider));
});
