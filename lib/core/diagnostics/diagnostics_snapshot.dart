import 'package:open_vts/core/diagnostics/api_diagnostics.dart';

class DiagnosticsSnapshot {
  const DiagnosticsSnapshot({
    required this.appVersion,
    required this.environment,
    required this.deviceInfo,
    required this.userRole,
    required this.socketConnected,
    required this.reconnectCount,
    required this.droppedTelemetryPackets,
    required this.activeMarkerCount,
    required this.recentApiFailures,
    this.tenantId,
    this.lastTelemetryAt,
  });

  final String appVersion;
  final String environment;
  final String deviceInfo;
  final String userRole;
  final String? tenantId;
  final bool socketConnected;
  final DateTime? lastTelemetryAt;
  final int reconnectCount;
  final int droppedTelemetryPackets;
  final int activeMarkerCount;
  final List<SafeApiFailureSummary> recentApiFailures;
}
