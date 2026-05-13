import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_snapshot.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';
import 'package:open_vts/features/map/domain/entities/vehicle_marker_state.dart';
import 'package:open_vts/features/map/presentation/open_vts_map/open_vts_map_marker_projection.dart';

void main() {
  test('projects typed marker state into UI-ready map points', () {
    final state = VehicleMarkerState(
      latestByVehicle: {
        '123': TelemetryPoint(
          vehicleId: 'vehicle-1',
          imei: '123',
          latitude: 28.6139,
          longitude: 77.209,
          speedKph: 42,
          heading: 90,
          ignition: true,
          recordedAt: DateTime.utc(2026),
        ),
      },
    );

    final points = OpenVtsMapMarkerProjection.fromMarkerState(state);

    expect(points, hasLength(1));
    expect(points.single.imei, '123');
    expect(points.single.lat, 28.6139);
    expect(points.single.lng, 77.209);
  });

  test('drops invalid snapshots before they reach marker layer', () {
    final points = OpenVtsMapMarkerProjection.fromSnapshots([
      MapVehicleSnapshot(
        vehicleId: 'v1',
        imei: '123',
        plateNumber: 'DL01',
        lat: 0,
        lng: 0,
        speedKph: 0,
        heading: 0,
        ignition: false,
        status: 'stopped',
        vehicleTypeName: 'Car',
        serverTime: null,
        deviceTime: null,
        lastUpdate: null,
      ),
    ]);

    expect(points, isEmpty);
  });
}
