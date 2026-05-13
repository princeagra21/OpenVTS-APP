import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';
import 'package:open_vts/features/map/domain/entities/vehicle_marker_state.dart';
import 'package:open_vts/features/map/presentation/open_vts_map/open_vts_map_marker_projection.dart';

void main() {
  test('OpenVTS map projection merges live telemetry into existing points', () {
    final now = DateTime.utc(2026, 1, 1, 10);
    final current = [
      MapVehiclePoint(<String, dynamic>{
        'vehicleId': 'v1',
        'imei': '123',
        'lat': 10.0,
        'lng': 20.0,
        'heading': 0.0,
      }),
    ];

    final state = VehicleMarkerState(
      latestByVehicle: {
        '123': TelemetryPoint(
          vehicleId: 'v1',
          imei: '123',
          latitude: 11.0,
          longitude: 21.0,
          speedKph: 35.0,
          heading: 90.0,
          ignition: true,
          recordedAt: now,
          raw: const <String, Object?>{},
        ),
      },
      lastFlushAt: now,
    );

    final projected = OpenVtsMapMarkerProjection.mergeLiveTelemetry(
      currentPoints: current,
      markerState: state,
    );

    expect(projected, isNot(same(current)));
    expect(projected.single.lat, 11.0);
    expect(projected.single.lng, 21.0);
    expect(projected.single.heading, 90.0);
  });

  test('projection returns same list when no marker updates exist', () {
    final current = [
      MapVehiclePoint(<String, dynamic>{
        'vehicleId': 'v1',
        'imei': '123',
        'lat': 10.0,
        'lng': 20.0,
      }),
    ];

    final projected = OpenVtsMapMarkerProjection.mergeLiveTelemetry(
      currentPoints: current,
      markerState: const VehicleMarkerState.empty(),
    );

    expect(identical(projected, current), true);
  });

}
