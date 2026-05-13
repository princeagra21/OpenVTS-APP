import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/map/data/mappers/map_vehicle_snapshot_mapper.dart';

void main() {
  const mapper = MapVehicleSnapshotMapper();

  test('valid backend map converts to typed snapshot', () {
    final snapshot = mapper.fromBackendMap({
      'vehicleId': 'vehicle-1',
      'imei': '123456789012345',
      'plateNumber': 'DL01AB1234',
      'lat': '28.6139',
      'lng': 77.2090,
      'speed': 42,
      'heading': '90',
      'ignition': 'true',
      'status': 'running',
      'vehicleType': {'name': 'Truck'},
      'serverTime': '2026-05-11T10:00:00.000Z',
    });

    expect(snapshot, isNotNull);
    expect(snapshot!.vehicleId, 'vehicle-1');
    expect(snapshot.imei, '123456789012345');
    expect(snapshot.plateNumber, 'DL01AB1234');
    expect(snapshot.lat, 28.6139);
    expect(snapshot.lng, 77.2090);
    expect(snapshot.speedKph, 42);
    expect(snapshot.heading, 90);
    expect(snapshot.ignition, true);
    expect(snapshot.vehicleTypeName, 'Truck');
  });

  test('invalid latitude and longitude are rejected', () {
    final snapshot = mapper.fromBackendMap({
      'vehicleId': 'vehicle-1',
      'imei': '123456789012345',
      'lat': 0,
      'lng': 0,
    });

    expect(snapshot, isNull);
  });

  test('nested telemetry fallback keys are supported', () {
    final snapshot = mapper.fromBackendMap({
      'id': 'vehicle-2',
      'deviceImei': '987654321098765',
      'latestTelemetry': {
        'latitude': 29.1,
        'longitude': 78.2,
        'speedKph': '18.5',
        'course': 120,
        'acc': 1,
        'deviceTime': '2026-05-11T11:00:00.000Z',
      },
    });

    expect(snapshot, isNotNull);
    expect(snapshot!.lat, 29.1);
    expect(snapshot.lng, 78.2);
    expect(snapshot.speedKph, 18.5);
    expect(snapshot.ignition, true);
    expect(snapshot.deviceTime, isNotNull);
  });
}
