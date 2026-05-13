import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_vehicle_mapper.dart';

void main() {
  test('SuperadminVehicleMapper maps vehicles and command options', () {
    const mapper = SuperadminVehicleMapper();
    final vehicles = mapper.vehiclesFromResponse(_response(data: {
      'vehicles': [
        {'vehicleId': 'v1', 'vehicleName': 'Truck 1', 'plateNumber': 'DL01', 'imei': '123'},
      ],
    })).map(mapper.listItem).toList();
    final commands = mapper.commandOptionsFromResponse(_response(data: {
      'commandtypes': [
        {'id': 'c1', 'name': 'Ping', 'code': 'ping'},
      ],
    }));

    expect(vehicles.single.id, 'v1');
    expect(vehicles.single.imei, '123');
    expect(commands.single.code, 'ping');
  });
}

Map<String, Object?> _response({Object? data}) => <String, Object?>{
      'status': 'success',
      'data': <String, Object?>{'action': true, 'message': '', 'data': data},
    };
