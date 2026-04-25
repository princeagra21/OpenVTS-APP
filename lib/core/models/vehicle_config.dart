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
      'speedVariation': _clean(speedMultiplier),
      'distanceVariation': _clean(distanceMultiplier),
    };
    if (odometer != null) map['odometer'] = _clean(odometer!);
    if (engineHours != null) map['engineHours'] = _clean(engineHours!);
    if (ignitionSource != null) {
      map['ignitionSource'] = _normalizeIgnitionSource(ignitionSource!);
    }
    return map;
  }

  dynamic _clean(double value) {
    if (value == value.toInt()) {
      return value.toInt();
    }
    return value;
  }

  String _normalizeIgnitionSource(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return value;
    if (normalized == 'acc' || normalized.contains('ignition')) {
      return 'ACC';
    }
    if (normalized == 'motion' || normalized.contains('motion')) {
      return 'MOTION';
    }
    return value;
  }
}
