import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/telemetry/telemetry_backpressure_policy.dart';
import 'package:open_vts/core/telemetry/telemetry_buffer.dart';
import 'package:open_vts/core/telemetry/telemetry_deduplicator.dart';
import 'package:open_vts/core/telemetry/telemetry_parser.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';

void main() {
  test('TelemetryParser creates typed point from raw packet', () {
    final point = const TelemetryParser().parse({
      'imei': '123',
      'latitude': 28.1,
      'longitude': 77.2,
      'speed': 42,
      'timestamp': '2026-05-11T00:00:00.000Z',
    });

    expect(point, isNotNull);
    expect(point!.imei, '123');
    expect(point.speedKph, 42);
    expect(point.hasValidPosition, true);
  });

  test('TelemetryDeduplicator rejects duplicate packets', () {
    final deduplicator = TelemetryDeduplicator();
    final point = TelemetryPoint(
      vehicleId: 'v1',
      imei: '123',
      latitude: 28.1,
      longitude: 77.2,
      recordedAt: DateTime.utc(2026),
      sequence: 's1',
    );

    expect(deduplicator.shouldAccept(point), true);
    expect(deduplicator.shouldAccept(point), false);
  });

  test('TelemetryBuffer batches latest point per vehicle', () async {
    final flushed = <Map<String, TelemetryPoint>>[];
    final buffer = TelemetryBuffer(
      policy: const TelemetryBackpressurePolicy(flushInterval: Duration(milliseconds: 10)),
    )..onFlush = flushed.add;

    buffer
      ..add(TelemetryPoint(
        vehicleId: 'v1',
        imei: '123',
        latitude: 28.1,
        longitude: 77.2,
        recordedAt: DateTime.utc(2026),
      ))
      ..add(TelemetryPoint(
        vehicleId: 'v1',
        imei: '123',
        latitude: 28.2,
        longitude: 77.3,
        recordedAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      ));

    await Future<void>.delayed(const Duration(milliseconds: 30));
    buffer.dispose();

    expect(flushed, hasLength(1));
    expect(flushed.single['123']?.latitude, 28.2);
  });
}
