import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/vehicles/data/mappers/vehicle_details_mapper.dart';

void main() {
  test('vehicle details mapper normalizes nested fallback backend keys', () {
    const mapper = VehicleDetailsMapper();

    final details = mapper.fromResponse(<String, Object?>{
      'data': <String, Object?>{
        'action': true,
        'data': <String, Object?>{
          'vehicle': <String, Object?>{
            'vehicleId': 'v-1',
            'vehicle_name': 'Truck One',
            'registration_number': 'DL01AB1234',
            'is_active': 1,
            'vehicleType': <String, Object?>{'title': 'Truck'},
            'device': <String, Object?>{
              'imei': '1234567890',
              'sim': <String, Object?>{
                'number': '9999999999',
                'provider': <String, Object?>{'name': 'Airtel'},
              },
            },
          },
          'telemetry': <String, Object?>{
            'last_seen_at': '2026-05-10T10:00:00Z',
            'currentSpeed': 42,
            'address': 'Delhi',
          },
        },
      },
    });

    expect(details.id, 'v-1');
    expect(details.name, 'Truck One');
    expect(details.plate, 'DL01AB1234');
    expect(details.isActive, isTrue);
    expect(details.type, 'Truck');
    expect(details.imei, '1234567890');
    expect(details.simNumber, '9999999999');
    expect(details.simProviderName, 'Airtel');
    expect(details.speed, '42');
    expect(details.locationName, 'Delhi');
  });
}
