/// Unified vehicle item model for shared vehicle feature
class VehicleItem {
  final Map<String, Object?> raw;

  const VehicleItem(this.raw);

  String get id => _string(
    raw['id'] ??
        raw['vehicleId'] ??
        raw['vehicle_id'] ??
        raw['uid'] ??
        raw['_id'] ??
        raw['uuid'],
  );

  String get name => _string(
    raw['name'] ??
        raw['vehicleName'] ??
        raw['title'] ??
        raw['model'] ??
        raw['plateNumber'],
  );

  String get plateNumber => _string(
    raw['plateNumber'] ??
        raw['plate'] ??
        raw['registrationNumber'] ??
        raw['registrationNo'],
  );

  String get vin => _string(
    raw['vin'] ??
        raw['VIN'] ??
        raw['chassisNumber'] ??
        raw['chassisNo'] ??
        raw['vehicleVin'],
  );

  String get imei => _string(
    raw['imei'] ??
        raw['deviceImei'] ??
        raw['device_imei'] ??
        raw['imeiNumber'] ??
        _mapValue(raw['device'], 'imei') ??
        _mapValue(raw['device'], 'imeiNumber'),
  );

  String get simNumber => _string(
    raw['simNumber'] ??
        raw['sim_number'] ??
        raw['simNo'] ??
        raw['sim'],
  );

  String get type => _string(
    raw['type'] ??
        raw['vehicleType'] ??
        raw['vehicleTypeName'] ??
        raw['vehicle_type_name'] ??
        _mapValue(raw['vehicleType'], 'name') ??
        _mapValue(raw['vehicleType'], 'title'),
  );

  String get status => _string(
    raw['status'] ??
        raw['state'] ??
        raw['vehicleStatus'] ??
        raw['liveStatus'],
  );

  String get motion => _string(
    raw['motion'] ??
        raw['movement'] ??
        raw['movementStatus'] ??
        raw['status'] ??
        raw['state'],
  );

  String get speed => _string(
    raw['speed'] ??
        raw['speedKph'] ??
        raw['currentSpeed'],
  );

  String get engine => _string(
    raw['engine'] ??
        raw['engineStatus'] ??
        raw['ignition'] ??
        raw['ignitionStatus'],
  );

  String get driverName => _string(
    raw['driverName'] ??
        raw['driver'] ??
        _mapValue(raw['primaryUser'], 'name') ??
        _mapValue(raw['userPrimary'], 'name') ??
        raw['primaryUserName'] ??
        raw['primary_user_name'],
  );

  String get userPrimaryName => _string(
    (raw['userPrimary'] is Map
            ? (raw['userPrimary'] as Map)['name'] ??
                  (raw['userPrimary'] as Map)['fullName']
            : null) ??
        raw['primaryUserName'] ??
        raw['primary_user_name'] ??
        driverName,
  );

  String get userAddedByName => _string(
    (raw['userAddedBy'] is Map
            ? (raw['userAddedBy'] as Map)['name'] ??
                  (raw['userAddedBy'] as Map)['fullName'] ??
                  (raw['userAddedBy'] as Map)['username']
            : null) ??
        raw['addedByName'] ??
        raw['added_by_name'],
  );

  String get createdAt => _string(raw['createdAt'] ?? raw['created_at']);
  String get updatedAt => _string(raw['updatedAt'] ?? raw['updated_at']);

  bool get isActive => raw['isActive'] == true || raw['active'] == true;

  Object? _mapValue(Object? source, String key) {
    if (source is Map) return source[key];
    return null;
  }

  String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
