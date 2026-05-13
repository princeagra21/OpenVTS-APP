import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_snapshot.dart';
import 'package:open_vts/features/map/domain/entities/vehicle_marker_state.dart';

/// Converts typed, throttled live marker state into the existing map marker
/// view model used by the current OpenVTS map UI.
///
/// Raw backend-key fallback parsing belongs to MapVehicleSnapshotMapper. This
/// projection only transforms typed domain snapshots into marker-ready data.
class OpenVtsMapMarkerProjection {
  const OpenVtsMapMarkerProjection._();

  static List<MapVehiclePoint> fromMarkerState(VehicleMarkerState markerState) {
    if (markerState.latestByVehicle.isEmpty) return const [];
    return fromSnapshots(
      markerState.latestByVehicle.values.map(MapVehicleSnapshot.fromTelemetryPoint),
    );
  }

  static List<MapVehiclePoint> fromSnapshots(
    Iterable<MapVehicleSnapshot> snapshots,
  ) {
    final points = <MapVehiclePoint>[];
    for (final snapshot in snapshots) {
      if (!snapshot.hasValidPosition) continue;
      points.add(_mapPointFromSnapshot(snapshot));
    }
    return points;
  }

  static List<MapVehiclePoint> mergeLiveTelemetry({
    required List<MapVehiclePoint> currentPoints,
    required VehicleMarkerState markerState,
  }) {
    if (markerState.latestByVehicle.isEmpty) return currentPoints;

    final snapshots = markerState.latestByVehicle.values
        .map(MapVehicleSnapshot.fromTelemetryPoint)
        .where((snapshot) => snapshot.hasValidPosition)
        .toList(growable: false);
    if (snapshots.isEmpty) return currentPoints;

    final updates = <String, MapVehicleSnapshot>{};
    for (final snapshot in snapshots) {
      final key = snapshot.markerKey;
      if (key.isNotEmpty) updates[key] = snapshot;
    }
    if (updates.isEmpty) return currentPoints;

    var changed = false;
    final nextPoints = <MapVehiclePoint>[];
    final seen = <String>{};

    for (final point in currentPoints) {
      final key = point.imei.trim().isNotEmpty
          ? point.imei.trim()
          : point.vehicleId.trim();
      final live = updates[key];
      if (live == null) {
        nextPoints.add(point);
        if (key.isNotEmpty) seen.add(key);
        continue;
      }
      nextPoints.add(_pointWithSnapshot(point, live));
      seen.add(key);
      changed = true;
    }

    for (final entry in updates.entries) {
      if (seen.contains(entry.key)) continue;
      nextPoints.add(_mapPointFromSnapshot(entry.value));
      changed = true;
    }

    return changed ? nextPoints : currentPoints;
  }

  static MapVehiclePoint _pointWithSnapshot(
    MapVehiclePoint point,
    MapVehicleSnapshot snapshot,
  ) {
    return MapVehiclePoint(<String, dynamic>{
      ...point.raw,
      'vehicleId': point.vehicleId.isNotEmpty ? point.vehicleId : snapshot.vehicleId,
      'imei': point.imei.isNotEmpty ? point.imei : snapshot.imei,
      'plateNumber': point.plateNumber.isNotEmpty ? point.plateNumber : snapshot.plateNumber,
      'lat': snapshot.lat,
      'lng': snapshot.lng,
      'heading': snapshot.heading,
      'speedKph': snapshot.speedKph,
      'ignition': snapshot.ignition,
      'status': snapshot.status,
      'vehicleTypeName': snapshot.vehicleTypeName,
      'lastUpdate': snapshot.lastUpdate?.toIso8601String(),
      'latestTelemetry': <String, dynamic>{
        ...point.telemetry,
        'lat': snapshot.lat,
        'lng': snapshot.lng,
        'speedKph': snapshot.speedKph,
        'heading': snapshot.heading,
        'ignition': snapshot.ignition,
        'serverTime': snapshot.serverTime?.toIso8601String(),
        'deviceTime': snapshot.deviceTime?.toIso8601String(),
      },
    });
  }

  static MapVehiclePoint _mapPointFromSnapshot(MapVehicleSnapshot snapshot) {
    return MapVehiclePoint(<String, dynamic>{
      'vehicleId': snapshot.vehicleId,
      'imei': snapshot.imei,
      'plateNumber': snapshot.plateNumber,
      'lat': snapshot.lat,
      'lng': snapshot.lng,
      'heading': snapshot.heading,
      'speedKph': snapshot.speedKph,
      'ignition': snapshot.ignition,
      'status': snapshot.status,
      'vehicleTypeName': snapshot.vehicleTypeName,
      'serverTime': snapshot.serverTime?.toIso8601String(),
      'deviceTime': snapshot.deviceTime?.toIso8601String(),
      'lastUpdate': snapshot.lastUpdate?.toIso8601String(),
    });
  }
}
