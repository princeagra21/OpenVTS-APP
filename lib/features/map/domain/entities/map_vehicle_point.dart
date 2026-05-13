class MapVehiclePoint {
  MapVehiclePoint(Object? source)
      : vehicleId = _readString(_sourceMap(source), const ['vehicleId', 'vehicle_id', 'id', 'uuid']),
        imei = _readString(_sourceMap(source), const ['imei', 'deviceImei', 'imeiNumber']),
        plateNumber = _readString(_sourceMap(source), const ['plateNumber', 'plate', 'registrationNumber', 'name', 'vehicleName']),
        lat = _readDouble(_sourceMap(source), const ['lat', 'latitude', 'locationLat', 'location_lat']),
        lng = _readDouble(_sourceMap(source), const ['lng', 'lon', 'long', 'longitude', 'locationLng', 'location_lng']),
        speedKph = _readNullableDoubleWithTelemetry(source, const ['speedKph', 'speed_kph', 'speed', 'currentSpeed']),
        heading = _readNullableDouble(_sourceMap(source), const ['heading', 'course', 'bearing']),
        ignition = _readString(_sourceMap(source), const ['ignition', 'ignitionStatus', 'isIgnitionOn']),
        status = _readString(_sourceMap(source), const ['status', 'state', 'motion']),
        vehicleTypeName = _readVehicleTypeName(_sourceMap(source)),
        serverTime = _readStringWithTelemetry(source, const ['serverTime', 'server_time']),
        deviceTime = _readStringWithTelemetry(source, const ['deviceTime', 'device_time']),
        lastUpdate = _readLastUpdate(source);

  const MapVehiclePoint.typed({
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
  final double? speedKph;
  final double? heading;
  final String ignition;
  final String status;
  final String vehicleTypeName;
  final String serverTime;
  final String deviceTime;
  final String lastUpdate;

  double? get speed => speedKph;
  String get updatedAt => lastUpdate;
  bool get hasValidPoint => lat != 0 || lng != 0;

  Map<String, Object?> get telemetry => <String, Object?>{
        'speedKph': speedKph,
        'speed': speedKph,
        'heading': heading,
        'ignition': ignition,
        'serverTime': serverTime,
        'deviceTime': deviceTime,
      };

  Map<String, Object?> get raw => <String, Object?>{
        'vehicleId': vehicleId,
        'imei': imei,
        'plateNumber': plateNumber,
        'lat': lat,
        'lng': lng,
        'speedKph': speedKph,
        'heading': heading,
        'ignition': ignition,
        'status': status,
        'vehicleTypeName': vehicleTypeName,
        'serverTime': serverTime,
        'deviceTime': deviceTime,
        'lastUpdate': lastUpdate,
        'latestTelemetry': telemetry,
      };

  static Map<String, Object?> _sourceMap(Object? source) {
    if (source is MapVehiclePoint) {
      return <String, Object?>{
        'vehicleId': source.vehicleId,
        'imei': source.imei,
        'plateNumber': source.plateNumber,
        'lat': source.lat,
        'lng': source.lng,
        'speedKph': source.speedKph,
        'heading': source.heading,
        'ignition': source.ignition,
        'status': source.status,
        'vehicleTypeName': source.vehicleTypeName,
        'serverTime': source.serverTime,
        'deviceTime': source.deviceTime,
        'lastUpdate': source.lastUpdate,
      };
    }
    if (source is Map) {
      return <String, Object?>{for (final entry in source.entries) entry.key.toString(): entry.value};
    }
    return const <String, Object?>{};
  }

  static Map<String, Object?> _telemetryMap(Object? source) {
    final raw = _sourceMap(source);
    for (final key in const ['telemetry', 'latestTelemetry', 'latest_telemetry', 'lastTelemetry', 'telemetryData', 'telemetry_data']) {
      final value = raw[key];
      if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    }
    return const <String, Object?>{};
  }

  static String _readString(Map<String, Object?> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static String _readStringWithTelemetry(Object? source, List<String> keys) {
    final direct = _readString(_sourceMap(source), keys);
    if (direct.isNotEmpty) return direct;
    return _readString(_telemetryMap(source), keys);
  }

  static String _readLastUpdate(Object? source) {
    final direct = _readStringWithTelemetry(source, const [
      'lastUpdate',
      'last_update',
      'updatedAt',
      'updated_at',
      'lastSeen',
      'lastSeenAt',
      'last_seen_at',
      'timestamp',
      'time',
    ]);
    if (direct.isNotEmpty) return direct;
    final server = _readStringWithTelemetry(source, const ['serverTime', 'server_time']);
    if (server.isNotEmpty) return server;
    return _readStringWithTelemetry(source, const ['deviceTime', 'device_time']);
  }

  static double _readDouble(Map<String, Object?> raw, List<String> keys) {
    return _readNullableDouble(raw, keys) ?? 0;
  }

  static double? _readNullableDouble(Map<String, Object?> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _readNullableDoubleWithTelemetry(Object? source, List<String> keys) {
    return _readNullableDouble(_sourceMap(source), keys) ?? _readNullableDouble(_telemetryMap(source), keys);
  }

  static String _readVehicleTypeName(Map<String, Object?> raw) {
    final candidates = <Object?>[
      raw['vehicleTypeName'],
      raw['vehicle_type_name'],
      raw['vehicle_type'],
      raw['type'],
      raw['vehicleType'],
      raw['vehicletype'],
      raw['vehicle_class'],
      raw['vehicleClass'],
      raw['typeName'],
      raw['type_name'],
    ];
    for (final candidate in candidates) {
      final value = _vehicleTypeLabel(candidate);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _vehicleTypeLabel(Object? value) {
    if (value == null) return '';
    if (value is Map) {
      final map = <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
      final nested = map['vehicleType'] is Map ? _vehicleTypeLabel(map['vehicleType']) : '';
      if (nested.isNotEmpty) return nested;
      for (final key in const ['name', 'title', 'type', 'slug', 'label', 'code', 'displayName', 'display_name']) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }
    final text = value.toString().trim();
    if (text.startsWith('{') && text.endsWith('}')) return '';
    return text;
  }
}
