import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';

/// Typed live-map vehicle snapshot used by the map marker pipeline.
///
/// This entity intentionally contains no raw backend map. Flexible backend keys
/// are normalized by data mappers before this object reaches presentation.
class MapVehicleSnapshot {
  const MapVehicleSnapshot({
    required this.vehicleId,
    required this.imei,
    required this.plateNumber,
    required this.lat,
    required this.lng,
    required this.speedKph,
    required this.heading,
    required this.ignition,
    required this.status,
    required this.vehicleTypeName,
    required this.serverTime,
    required this.deviceTime,
    required this.lastUpdate,
  });

  final String vehicleId;
  final String imei;
  final String plateNumber;
  final double lat;
  final double lng;
  final double speedKph;
  final double heading;
  final bool ignition;
  final String status;
  final String vehicleTypeName;
  final DateTime? serverTime;
  final DateTime? deviceTime;
  final DateTime? lastUpdate;

  bool get hasValidPosition =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 && !(lat == 0 && lng == 0);

  String get markerKey => imei.trim().isNotEmpty ? imei.trim() : vehicleId.trim();

  DateTime get recordedAt => lastUpdate ?? serverTime ?? deviceTime ?? DateTime.now();

  TelemetryPoint toTelemetryPoint() {
    return TelemetryPoint(
      vehicleId: vehicleId.trim().isNotEmpty ? vehicleId : imei,
      imei: imei.trim().isNotEmpty ? imei : vehicleId,
      latitude: lat,
      longitude: lng,
      recordedAt: recordedAt,
      speedKph: speedKph,
      heading: heading,
      ignition: ignition,
      sequence: '${recordedAt.toIso8601String()}|$lat|$lng',
    );
  }

  factory MapVehicleSnapshot.fromTelemetryPoint(TelemetryPoint point) {
    return MapVehicleSnapshot(
      vehicleId: point.vehicleId,
      imei: point.imei,
      plateNumber: point.imei,
      lat: point.latitude,
      lng: point.longitude,
      speedKph: point.speedKph,
      heading: point.heading,
      ignition: point.ignition,
      status: point.ignition || point.speedKph > 0 ? 'moving' : 'stopped',
      vehicleTypeName: '',
      serverTime: point.recordedAt,
      deviceTime: point.recordedAt,
      lastUpdate: point.recordedAt,
    );
  }
}
