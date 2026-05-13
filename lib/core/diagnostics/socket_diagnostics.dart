import 'dart:async';

import 'package:open_vts/core/observability/observability_service.dart';

class SocketDiagnostics {
  SocketDiagnostics({ObservabilityService? observability})
      : _observability = observability;

  final ObservabilityService? _observability;

  int reconnectCount = 0;
  int droppedTelemetryPackets = 0;
  int bufferFlushCount = 0;
  DateTime? lastTelemetryAt;
  bool socketConnected = false;

  void recordConnected() {
    socketConnected = true;
    unawaited(
      _observability?.addBreadcrumb('socket', 'socket_connected') ?? Future<void>.value(),
    );
  }

  void recordDisconnected() {
    socketConnected = false;
    unawaited(
      _observability?.addBreadcrumb('socket', 'socket_disconnected') ?? Future<void>.value(),
    );
  }

  void recordReconnect() {
    reconnectCount += 1;
    socketConnected = true;
    unawaited(
      _observability?.addBreadcrumb(
            'socket',
            'socket_reconnected',
            data: <String, Object?>{'reconnectCount': reconnectCount},
          ) ??
          Future<void>.value(),
    );
    unawaited(
      _observability?.recordMetric('socket.reconnect_count', reconnectCount) ?? Future<void>.value(),
    );
  }

  void recordTelemetryReceived() {
    lastTelemetryAt = DateTime.now();
  }

  void recordTelemetryDropped() {
    droppedTelemetryPackets += 1;
    unawaited(
      _observability?.recordMetric(
            'telemetry.dropped_packets',
            droppedTelemetryPackets,
          ) ??
          Future<void>.value(),
    );
  }

  void recordBufferFlush() {
    bufferFlushCount += 1;
    unawaited(
      _observability?.recordMetric('telemetry.buffer_flush_count', bufferFlushCount) ?? Future<void>.value(),
    );
  }
}
