class AdminVehicleDetails {
  final Map<String, dynamic> raw;

  const AdminVehicleDetails(this.raw);

  factory AdminVehicleDetails.fromRaw(Map<String, dynamic> raw) {
    return AdminVehicleDetails(raw);
  }

  String get nameModel => _s(
        raw['model'] ?? raw['name'] ?? raw['vehicleName'] ?? raw['plateNumber'],
      );

  String get imei => _s(raw['imei'] ?? raw['deviceImei'] ?? raw['imeiNumber']);

  String get vin => _s(raw['vin'] ?? raw['chassisNo'] ?? raw['vehicleVin']);

  String get status => _s(
        raw['motion'] ?? raw['status'] ?? raw['state'] ?? raw['liveStatus'],
      );

  String get duration =>
      _s(raw['duration'] ?? raw['elapsed'] ?? raw['uptime'] ?? raw['age']);

  String get speed => _s(raw['speed'] ?? raw['currentSpeed'] ?? raw['velocity']);

  String get primaryUser {
    final nested = _asMap(raw['primaryUser']);
    return _s(
      nested['name'] ??
          raw['primaryUserName'] ??
          raw['userName'] ??
          raw['ownerName'] ??
          raw['driverName'],
    );
  }

  String get primaryUserInitials {
    final name = primaryUser.trim();
    if (name.isEmpty) return '--';
    final parts = name.split(RegExp(r'\\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) {
      final single = parts.first;
      return single.length >= 2
          ? single.substring(0, 2).toUpperCase()
          : single.toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  String get lastUpdate => _s(
        raw['lastUpdate'] ??
            raw['lastSeenAt'] ??
            raw['lastSeen'] ??
            raw['updatedAt'] ??
            raw['timestamp'],
      );

  String get fuelLevel =>
      _s(raw['fuelLevel'] ?? raw['fuel'] ?? raw['fuelPercentage']);

  String get odometer =>
      _s(raw['odometer'] ?? raw['odometerKm'] ?? raw['distance']);

  String get sim =>
      _s(raw['sim'] ?? raw['simNumber'] ?? raw['simCard'] ?? raw['simNo']);

  String get deviceModel =>
      _s(raw['deviceModel'] ?? raw['device'] ?? raw['deviceType'] ?? raw['imeiDevice']);

  List<String> get geofences {
    final value = raw['geofence'] ?? raw['geofences'] ?? raw['geoFences'];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final asString = _s(value);
    if (asString.isEmpty) return const [];
    return [asString];
  }

  bool? get ignitionOk =>
      _b(raw['ignition'] ?? raw['ignitionOk'] ?? raw['ignitionStatus']);

  bool? get gpsOk => _b(raw['gps'] ?? raw['gpsOk'] ?? raw['gpsStatus']);

  bool? get lockOk => _b(raw['lock'] ?? raw['locked'] ?? raw['lockStatus']);

  String get active => _s(raw['active'] ?? raw['isActive'] ?? raw['enabled']);

  String get expiry => _s(
        raw['expiry'] ??
            raw['planExpiry'] ??
            raw['licenseExpiry'] ??
            raw['expiryDate'],
      );

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static String _s(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }

  static bool? _b(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'on') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'off') return false;
    return null;
  }
}
