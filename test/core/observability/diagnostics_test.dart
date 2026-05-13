import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/diagnostics/api_diagnostics.dart';
import 'package:open_vts/core/diagnostics/map_performance_diagnostics.dart';
import 'package:open_vts/core/diagnostics/socket_diagnostics.dart';

void main() {
  test('api diagnostics stores safe failure summaries only', () {
    final diagnostics = ApiDiagnostics();
    diagnostics.recordFailure(
      const SafeApiFailureSummary(
        endpointPattern: '/admin/users',
        method: 'POST',
        statusCode: 500,
        errorType: 'ServerError',
      ),
    );

    expect(diagnostics.recentFailures.single.endpointPattern, '/admin/users');
  });

  test('socket diagnostics tracks reconnect and dropped packets', () {
    final diagnostics = SocketDiagnostics()
      ..recordReconnect()
      ..recordTelemetryDropped();

    expect(diagnostics.reconnectCount, 1);
    expect(diagnostics.droppedTelemetryPackets, 1);
    expect(diagnostics.socketConnected, isTrue);
  });

  test('map diagnostics records marker batch size', () {
    final diagnostics = MapPerformanceDiagnostics()
      ..recordMarkerBatch(markerCount: 42, batchSize: 5);

    expect(diagnostics.activeMarkerCount, 42);
    expect(diagnostics.lastBatchSize, 5);
  });
}
