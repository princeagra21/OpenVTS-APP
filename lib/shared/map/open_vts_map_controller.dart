import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OpenVtsMapController {
  static const double defaultMapZoom = 13.0;
  static const double vehicleFocusZoom = 16.0;
  static const double followVehicleMinZoom = 16.0;
  static const double vehicleAssetHeadingOffset = 180;
  static const double samePointTolerance = 0.00001;

  final MapController mapController = MapController();

  double normalizeDegrees(double degrees) {
    final value = degrees % 360;
    return value < 0 ? value + 360 : value;
  }

  double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180.0;
    final lon1 = from.longitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final lon2 = to.longitude * math.pi / 180.0;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return normalizeDegrees(bearing);
  }

  double correctedVehicleHeading(double rawBearing) {
    return normalizeDegrees(rawBearing + vehicleAssetHeadingOffset);
  }

  bool isSameLatLngCloseEnough(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() <= samePointTolerance &&
        (a.longitude - b.longitude).abs() <= samePointTolerance;
  }
}
