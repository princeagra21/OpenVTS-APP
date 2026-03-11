class UserVehicleDetails {
  final Map<String, dynamic> raw;

  const UserVehicleDetails(this.raw);

  factory UserVehicleDetails.fromRaw(Map<String, dynamic> raw) {
    return UserVehicleDetails(raw);
  }

  String get id => _s(raw['id'] ?? raw['vehicleId'] ?? raw['_id']);

  String get name => _s(raw['name'] ?? raw['vehicleName'] ?? raw['title']);

  String get plateNumber => _s(
    raw['plateNumber'] ??
        raw['plate_number'] ??
        raw['plate'] ??
        raw['registrationNumber'],
  );

  String get displayTitle {
    final plate = plateNumber.trim();
    if (plate.isNotEmpty) return plate;
    final vehicleName = name.trim();
    if (vehicleName.isNotEmpty) return vehicleName;
    return id.trim().isEmpty ? 'Vehicle' : 'Vehicle $id';
  }

  String get vin => _s(raw['vin'] ?? raw['VIN'] ?? raw['chassisNumber']);

  bool get isActive {
    final value = raw['isActive'] ?? raw['active'] ?? raw['is_active'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = _s(value).toLowerCase();
    if (text == 'true' || text == '1' || text == 'active') return true;
    if (text == 'false' || text == '0' || text == 'inactive') return false;
    return false;
  }

  String get statusLabel {
    final direct = _s(raw['status'] ?? raw['state'] ?? raw['motion']);
    if (direct.trim().isNotEmpty) return direct.trim();
    return isActive ? 'Active' : 'Inactive';
  }

  String get createdAt =>
      _s(raw['createdAt'] ?? raw['created_at'] ?? raw['created']);

  String get imei {
    final direct = _s(raw['imei'] ?? raw['deviceImei'] ?? raw['imeiNumber']);
    if (direct.isNotEmpty) return direct;
    final device = _m(raw['device']);
    return _s(device['imei']);
  }

  String get simNumber =>
      _s(raw['simNumber'] ?? raw['sim'] ?? raw['simNo'] ?? raw['sim_number']);

  String get vehicleTypeName {
    final nested = _m(raw['vehicleType']);
    final fromNested = _s(nested['name'] ?? nested['title'] ?? nested['slug']);
    if (fromNested.isNotEmpty) return fromNested;
    return _s(raw['vehicleTypeName'] ?? raw['vehicleType'] ?? raw['type']);
  }

  String get gmtOffset =>
      _s(raw['gmtOffset'] ?? raw['gmt_offset'] ?? raw['timezone'] ?? raw['tz']);

  Map<String, dynamic> get device => _m(raw['device']);

  String get deviceId => _s(device['id']);
  String get deviceImei => _s(device['imei'] ?? imei);
  String get speedVariation => _s(device['speedVariation']);
  String get distanceVariation => _s(device['distanceVariation']);
  String get odometer => _s(device['odometer']);
  String get engineHours => _s(device['engineHours']);
  String get ignitionSource => _s(device['ignitionSource']);

  Map<String, dynamic> get plan => _m(raw['plan']);

  String get planName => _s(plan['name']);
  double? get planPrice => _d(plan['price']);
  String get planCurrency => _s(plan['currency']);

  static Map<String, dynamic> _m(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static String _s(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.toLowerCase() == 'null') return '';
    return text;
  }

  static double? _d(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }
}
