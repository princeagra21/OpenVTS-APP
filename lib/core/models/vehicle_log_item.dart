class VehicleLogItem {
  final Map<String, dynamic> raw;

  const VehicleLogItem(this.raw);

  String get time => _s(
    raw['time'] ??
        raw['timestamp'] ??
        raw['createdAt'] ??
        raw['created_at'] ??
        raw['date'],
  );

  String get type =>
      _s(raw['type'] ?? raw['eventType'] ?? raw['event'] ?? raw['logType']);

  String get message => _s(
    raw['message'] ??
        raw['msg'] ??
        raw['description'] ??
        raw['details'] ??
        raw['text'],
  );

  double? get lat => _d(
    raw['lat'] ?? raw['latitude'] ?? raw['locationLat'] ?? raw['location_lat'],
  );

  double? get lng => _d(
    raw['lng'] ??
        raw['lon'] ??
        raw['long'] ??
        raw['longitude'] ??
        raw['locationLng'] ??
        raw['location_lng'],
  );

  double? get speed => _d(raw['speed'] ?? raw['currentSpeed']);

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  static double? _d(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
