class VehicleConfig {
  final Map<String, dynamic> raw;

  const VehicleConfig(this.raw);

  double? get speedMultiplier => _d(
    raw['speedVariation'] ?? raw['speedMultiplier'] ?? raw['speedLimit'],
  );

  double? get distanceMultiplier => _d(
    raw['distanceVariation'] ??
        raw['distanceMultiplier'] ??
        raw['fuelCapacity'],
  );

  double? get odometer =>
      _d(raw['odometer'] ?? raw['odometerKm'] ?? raw['odometer_km']);

  double? get engineHours =>
      _d(raw['engineHours'] ?? raw['engine_hours'] ?? raw['runtimeHours']);

  String? get ignitionSource => _s(raw['ignitionSource'] ?? raw['ignition_source']);

  String get updatedAt => _s(raw['updatedAt'] ?? raw['updated_at']) ?? '';

  static double? _d(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String? _s(Object? v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }
}

class VehicleConfigUpdate {
  final double speedMultiplier;
  final double distanceMultiplier;
  final double? odometer;
  final double? engineHours;
  final String? ignitionSource;

  const VehicleConfigUpdate({
    required this.speedMultiplier,
    required this.distanceMultiplier,
    this.odometer,
    this.engineHours,
    this.ignitionSource,
  });

  /// Postman update example uses these keys.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'speedVariation': speedMultiplier,
      'distanceVariation': distanceMultiplier,
    };
    if (odometer != null) map['odometer'] = odometer;
    if (engineHours != null) map['engineHours'] = engineHours;
    if (ignitionSource != null) map['ignitionSource'] = ignitionSource;
    return map;
  }
}
