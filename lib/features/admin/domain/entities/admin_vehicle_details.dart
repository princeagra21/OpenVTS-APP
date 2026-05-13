class AdminVehicleDetails {
  final Map<String, Object?> raw;

  const AdminVehicleDetails(this.raw);

  factory AdminVehicleDetails.fromRaw(Map<String, Object?> raw) {
    return AdminVehicleDetails(raw);
  }



  String get plate => _s(raw['plateNumber'] ?? raw['plate'] ?? raw['registrationNumber']);

  String get vehicleTypeName {
    final nested = _asMap(raw['vehicleType']);
    return _s(nested['name'] ?? raw['vehicleTypeName'] ?? raw['typeName']);
  }

  String get simNumber => _s(raw['simNumber'] ?? raw['sim'] ?? raw['simNo'] ?? raw['simCard']);

  String get primaryExpiry => _s(raw['primaryExpiry'] ?? raw['primaryExpiryDate'] ?? raw['expiry']);

  String get secondaryExpiry => _s(raw['secondaryExpiry'] ?? raw['secondaryExpiryDate']);

  Map<String, Object?> get deviceData => _asMap(raw['device']);

  String get speedVariation => _s(deviceData['speedVariation'] ?? deviceData['speedMultiplier']);

  String get distanceVariation => _s(deviceData['distanceVariation'] ?? deviceData['distanceMultiplier']);

  String get deviceOdometer => _s(deviceData['odometer'] ?? raw['odometer'] ?? raw['odometerKm']);

  String get engineHours => _s(deviceData['engineHours'] ?? raw['engineHours']);

  String get deviceStatus => _s(deviceData['status'] ?? raw['deviceStatus']);

  Map<String, Object?> get planData => _asMap(raw['plan']);

  String get planName => _s(planData['name'] ?? raw['planName']);

  String get planPrice => _s(planData['price'] ?? raw['planPrice']);

  String get planCurrency => _s(planData['currency'] ?? raw['planCurrency']);

  String get planDuration => _s(planData['durationDays'] ?? raw['planDuration']);

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

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value.cast());
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
