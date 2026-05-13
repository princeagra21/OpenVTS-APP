import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';
import 'package:open_vts/features/map/domain/entities/vehicle_marker_state.dart';

void main() {
  test('VehicleMarkerState merge keeps latest telemetry per vehicle', () {
    final initial = VehicleMarkerState(
      latestByVehicle: {
        '111': TelemetryPoint(
          vehicleId: 'v1',
          imei: '111',
          latitude: 28.1,
          longitude: 77.1,
          recordedAt: DateTime.utc(2026),
        ),
      },
    );

    final merged = initial.merge({
      '111': TelemetryPoint(
        vehicleId: 'v1',
        imei: '111',
        latitude: 28.2,
        longitude: 77.2,
        recordedAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      ),
      '222': TelemetryPoint(
        vehicleId: 'v2',
        imei: '222',
        latitude: 29.0,
        longitude: 78.0,
        recordedAt: DateTime.utc(2026),
      ),
    });

    expect(merged.latestByVehicle, hasLength(2));
    expect(merged.latestByVehicle['111']?.latitude, 28.2);
    expect(merged.lastFlushAt, isNotNull);
  });
}
