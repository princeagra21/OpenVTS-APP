class VehicleConfig {
  final Map<String, dynamic> raw;

  const VehicleConfig(this.raw);

  double? get speedMultiplier => _d(
    raw['speedMultiplier'] ?? raw['speed_multiplier'] ?? raw['speedLimit'],
  );

  double? get distanceMultiplier => _d(
    raw['distanceMultiplier'] ??
        raw['distance_multiplier'] ??
        raw['fuelCapacity'],
  );

  double? get odometer =>
      _d(raw['odometer'] ?? raw['odometerKm'] ?? raw['odometer_km']);

  double? get engineHours =>
      _d(raw['engineHours'] ?? raw['engine_hours'] ?? raw['runtimeHours']);

  String get updatedAt => _s(raw['updatedAt'] ?? raw['updated_at']);

  static double? _d(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}

class VehicleConfigUpdate {
  final double speedMultiplier;
  final double distanceMultiplier;
  final double? odometer;
  final double? engineHours;

  const VehicleConfigUpdate({
    required this.speedMultiplier,
    required this.distanceMultiplier,
    this.odometer,
    this.engineHours,
  });

  /// Postman update example uses these keys.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'speedLimit': speedMultiplier,
      'fuelCapacity': distanceMultiplier,
    };
  }
}
