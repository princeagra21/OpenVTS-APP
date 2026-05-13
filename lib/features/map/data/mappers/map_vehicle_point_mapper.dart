import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';

class MapVehiclePointMapper {
  const MapVehiclePointMapper();

  MapVehiclePoint fromBackend(Object? response) => MapVehiclePoint(response);
}
