class TelemetryPoint {
  const TelemetryPoint({
    required this.vehicleId,
    required this.imei,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.speedKph = 0,
    this.heading = 0,
    this.ignition = false,
    this.sequence,
    this.raw = const <String, Object?>{},
  });

  final String vehicleId;
  final String imei;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double speedKph;
  final double heading;
  final bool ignition;
  final String? sequence;
  final Map<String, Object?> raw;

  String get dedupeKey => '$imei|${sequence ?? recordedAt.toIso8601String()}|$latitude|$longitude';

  bool get hasValidPosition => latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 && !(latitude == 0 && longitude == 0);
}
