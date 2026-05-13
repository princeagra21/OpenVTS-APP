import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/telemetry/telemetry_deduplicator.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';

void main() {
  TelemetryPoint point(String sequence) {
    return TelemetryPoint(
      vehicleId: 'v1',
      imei: '123',
      latitude: 28.1,
      longitude: 77.2,
      recordedAt: DateTime.utc(2026),
      sequence: sequence,
    );
  }

  test('rejects duplicate vehicle timestamp sequence', () {
    final deduplicator = TelemetryDeduplicator();

    expect(deduplicator.shouldAccept(point('s1')), true);
    expect(deduplicator.shouldAccept(point('s1')), false);
    expect(deduplicator.shouldAccept(point('s2')), true);
  });

  test('evicts old keys when max key budget is exceeded', () {
    final deduplicator = TelemetryDeduplicator(maxKeys: 1);

    expect(deduplicator.shouldAccept(point('old')), true);
    expect(deduplicator.shouldAccept(point('new')), true);
    expect(deduplicator.shouldAccept(point('old')), true);
  });
}
