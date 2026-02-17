class VehicleLocation {
  final Map<String, dynamic> raw;

  const VehicleLocation(this.raw);

  double get lat => _d(
    raw['lat'] ??
        raw['latitude'] ??
        raw['locationLat'] ??
        raw['location_lat'] ??
        raw['y'],
  );

  double get lng => _d(
    raw['lng'] ??
        raw['lon'] ??
        raw['long'] ??
        raw['longitude'] ??
        raw['locationLng'] ??
        raw['location_lng'] ??
        raw['x'],
  );

  String get updatedAt => _s(
    raw['updatedAt'] ??
        raw['updated_at'] ??
        raw['lastSeen'] ??
        raw['lastSeenAt'] ??
        raw['timestamp'] ??
        raw['time'],
  );

  double? get speed => _dn(raw['speed'] ?? raw['currentSpeed']);

  double? get heading => _dn(raw['heading'] ?? raw['course'] ?? raw['bearing']);

  bool get hasValidPoint => lat != 0 || lng != 0;

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  static double _d(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _dn(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
