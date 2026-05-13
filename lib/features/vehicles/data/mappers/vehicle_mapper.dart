import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_models.dart' as legacy;

class VehicleMapper {
  const VehicleMapper._();



  static Vehicle fromMap(Map<String, dynamic> raw) {
    String value(List<String> keys) {
      for (final key in keys) {
        final found = raw[key];
        if (found != null && found.toString().trim().isNotEmpty) {
          return found.toString();
        }
      }
      return '';
    }

    return Vehicle(
      id: value(const ['id', '_id', 'vehicleId']),
      name: value(const ['name', 'vehicleName', 'title']),
      plateNumber: value(const ['plateNumber', 'plate', 'registrationNumber']),
      imei: value(const ['imei', 'deviceImei', 'deviceIMEI']),
      status: value(const ['status', 'motion', 'state']),
      raw: raw,
    );
  }

  static Vehicle fromLegacy(legacy.VehicleItem item) {
    return Vehicle(
      id: item.id,
      name: item.name,
      plateNumber: item.plateNumber,
      imei: item.imei,
      status: item.status.isNotEmpty ? item.status : item.motion,
      raw: item.raw,
    );
  }
}
