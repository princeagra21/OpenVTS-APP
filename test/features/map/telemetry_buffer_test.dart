import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/telemetry/telemetry_backpressure_policy.dart';
import 'package:open_vts/core/telemetry/telemetry_buffer.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';

void main() {
  TelemetryPoint point({
    required String imei,
    required double lat,
    required DateTime at,
  }) {
    return TelemetryPoint(
      vehicleId: 'vehicle-$imei',
      imei: imei,
      latitude: lat,
      longitude: 77.2,
      recordedAt: at,
    );
  }

  test('keeps latest point per vehicle until flush', () async {
    final flushed = <Map<String, TelemetryPoint>>[];
    final buffer = TelemetryBuffer(
      policy: const TelemetryBackpressurePolicy(
        flushInterval: Duration(milliseconds: 10),
      ),
    )..onFlush = flushed.add;

    buffer
      ..add(point(imei: '111', lat: 28.1, at: DateTime.utc(2026)))
      ..add(point(imei: '111', lat: 28.2, at: DateTime.utc(2026, 1, 1, 0, 0, 1)))
      ..add(point(imei: '222', lat: 29.1, at: DateTime.utc(2026)));

    await Future<void>.delayed(const Duration(milliseconds: 30));
    buffer.dispose();

    expect(flushed, hasLength(1));
    expect(flushed.single, hasLength(2));
    expect(flushed.single['111']?.latitude, 28.2);
  });

  test('flushes pending latest values on dispose', () {
    final flushed = <Map<String, TelemetryPoint>>[];
    final buffer = TelemetryBuffer(
      policy: const TelemetryBackpressurePolicy(
        flushInterval: Duration(seconds: 30),
      ),
    )..onFlush = flushed.add;

    buffer.add(point(imei: '333', lat: 30.1, at: DateTime.utc(2026)));
    buffer.dispose();

    expect(flushed, hasLength(1));
    expect(flushed.single['333']?.latitude, 30.1);
  });
}
