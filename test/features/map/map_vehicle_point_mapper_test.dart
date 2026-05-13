import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/map/data/mappers/map_vehicle_point_mapper.dart';
import 'package:open_vts/features/map/data/mappers/telemetry_data_mapper.dart';

void main() {
  test('map vehicle point mapper normalizes root and telemetry fallback keys', () {
    const mapper = MapVehiclePointMapper();

    final point = mapper.fromBackend(<String, Object?>{
      'vehicle_id': 'vehicle-1',
      'deviceImei': 'imei-1',
      'registrationNumber': 'RJ01AA0001',
      'locationLat': '26.9124',
      'location_lng': '75.7873',
      'vehicleType': <String, Object?>{'displayName': 'Car'},
      'latest_telemetry': <String, Object?>{
        'speed_kph': '55.5',
        'server_time': '2026-05-10T10:00:00Z',
      },
    });

    expect(point.vehicleId, 'vehicle-1');
    expect(point.imei, 'imei-1');
    expect(point.plateNumber, 'RJ01AA0001');
    expect(point.lat, 26.9124);
    expect(point.lng, 75.7873);
    expect(point.speedKph, 55.5);
    expect(point.vehicleTypeName, 'Car');
    expect(point.serverTime, '2026-05-10T10:00:00Z');
  });

  test('telemetry data mapper normalizes alternate position keys', () {
    const mapper = TelemetryDataMapper();

    final telemetry = mapper.fromBackend(<String, Object?>{
      'device_imei': 'imei-2',
      'lat': '28.6139',
      'lon': '77.2090',
      'speed_kph': '64',
      'course': 180,
      'isIgnitionOn': 'true',
    });

    expect(telemetry.imei, 'imei-2');
    expect(telemetry.latitude, 28.6139);
    expect(telemetry.longitude, 77.2090);
    expect(telemetry.speed, 64);
    expect(telemetry.heading, 180);
    expect(telemetry.ignition, isTrue);
  });
}
