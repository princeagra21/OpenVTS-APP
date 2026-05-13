class TelemetryData {
  const TelemetryData({
    required this.imei,
    required this.latitude,
    required this.longitude,
    this.speed = 0,
    this.heading = 0,
    this.ignition = false,
  });

  final String imei;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final bool ignition;

  factory TelemetryData.fromJson(Object? source) {
    final json = _map(source);
    return TelemetryData(
      imei: _string(json, const ['imei', 'deviceImei', 'device_imei']),
      latitude: _number(json, const ['latitude', 'lat']),
      longitude: _number(json, const ['longitude', 'lng', 'lon']),
      speed: _number(json, const ['speed', 'speedKph', 'speed_kph']),
      heading: _number(json, const ['heading', 'course', 'angle']),
      ignition: _boolean(json, const ['ignition', 'isIgnitionOn']),
    );
  }

  static Map<String, Object?> _map(Object? source) {
    if (source is Map) return <String, Object?>{for (final entry in source.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static String _string(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
    }
    return '';
  }

  static double _number(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static bool _boolean(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value?.toString().toLowerCase().trim();
      if (text == 'true' || text == '1' || text == 'on') return true;
      if (text == 'false' || text == '0' || text == 'off') return false;
    }
    return false;
  }
}
