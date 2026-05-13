import 'package:open_vts/core/diagnostics/api_diagnostics.dart';
import 'package:open_vts/core/diagnostics/diagnostics_snapshot.dart';
import 'package:open_vts/core/diagnostics/map_performance_diagnostics.dart';
import 'package:open_vts/core/diagnostics/socket_diagnostics.dart';
import 'package:open_vts/core/observability/observability_service.dart';

class DiagnosticsService {
  const DiagnosticsService({
    required ApiDiagnostics apiDiagnostics,
    required SocketDiagnostics socketDiagnostics,
    required MapPerformanceDiagnostics mapDiagnostics,
    required ObservabilityService observability,
  })  : _apiDiagnostics = apiDiagnostics,
        _socketDiagnostics = socketDiagnostics,
        _mapDiagnostics = mapDiagnostics,
        _observability = observability;

  final ApiDiagnostics _apiDiagnostics;
  final SocketDiagnostics _socketDiagnostics;
  final MapPerformanceDiagnostics _mapDiagnostics;
  final ObservabilityService _observability;

  DiagnosticsSnapshot snapshot({
    required String appVersion,
    required String environment,
    required String deviceInfo,
    required String userRole,
    String? tenantId,
  }) {
    return DiagnosticsSnapshot(
      appVersion: appVersion,
      environment: environment,
      deviceInfo: deviceInfo,
      userRole: userRole,
      tenantId: tenantId,
      socketConnected: _socketDiagnostics.socketConnected,
      lastTelemetryAt: _socketDiagnostics.lastTelemetryAt,
      reconnectCount: _socketDiagnostics.reconnectCount,
      droppedTelemetryPackets: _socketDiagnostics.droppedTelemetryPackets,
      activeMarkerCount: _mapDiagnostics.activeMarkerCount,
      recentApiFailures: _apiDiagnostics.recentFailures,
    );
  }

  Future<void> publishSnapshot(DiagnosticsSnapshot snapshot) {
    return _observability.addBreadcrumb(
      'diagnostics',
      'diagnostics_snapshot',
      data: <String, Object?>{
        'appVersion': snapshot.appVersion,
        'environment': snapshot.environment,
        'userRole': snapshot.userRole,
        'socketConnected': snapshot.socketConnected,
        'reconnectCount': snapshot.reconnectCount,
        'droppedTelemetryPackets': snapshot.droppedTelemetryPackets,
        'activeMarkerCount': snapshot.activeMarkerCount,
        'recentApiFailureCount': snapshot.recentApiFailures.length,
      },
    );
  }
}
