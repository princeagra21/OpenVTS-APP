import 'dart:async';

import 'package:open_vts/core/telemetry/telemetry_backpressure_policy.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';

class TelemetryBuffer {
  TelemetryBuffer({required this.policy});

  final TelemetryBackpressurePolicy policy;
  final Map<String, TelemetryPoint> _latestByVehicle = <String, TelemetryPoint>{};
  Timer? _timer;
  void Function(Map<String, TelemetryPoint> snapshot)? onFlush;

  void add(TelemetryPoint point) {
    _latestByVehicle[point.imei] = point;
    _timer ??= Timer(policy.flushInterval, _flush);
  }

  void _flush() {
    final snapshot = Map<String, TelemetryPoint>.from(_latestByVehicle);
    _latestByVehicle.clear();
    _timer = null;
    if (snapshot.isNotEmpty) onFlush?.call(snapshot);
  }

  void flushNow() {
    _timer?.cancel();
    _flush();
  }

  void dispose() {
    if (_latestByVehicle.isNotEmpty) {
      flushNow();
    }
    _timer?.cancel();
    _timer = null;
    _latestByVehicle.clear();
  }
}
