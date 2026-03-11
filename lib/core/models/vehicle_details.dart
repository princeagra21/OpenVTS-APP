import 'package:fleet_stack/core/models/vehicle_document_item.dart';
import 'package:fleet_stack/core/models/vehicle_user_item.dart';

class VehicleDetails {
  final Map<String, dynamic> raw;

  const VehicleDetails(this.raw);

  Map<String, dynamic> get payload {
    final root = _coerceMap(raw);
    final d = _coerceMap(root['data']);
    return d.isNotEmpty ? d : root;
  }

  Map<String, dynamic> get data {
    final root = payload;
    final vehicle = _coerceMap(root['vehicle']);
    if (vehicle.isNotEmpty) return vehicle;

    final nested = _coerceMap(root['data']);
    final nestedVehicle = _coerceMap(nested['vehicle']);
    if (nestedVehicle.isNotEmpty) return nestedVehicle;
    if (nested.isNotEmpty) return nested;
    return root;
  }

  Map<String, dynamic> get telemetry {
    final root = payload;
    final t = _coerceMap(root['telemetry']);
    if (t.isNotEmpty) return t;

    final nested = _coerceMap(root['data']);
    final nestedTelemetry = _coerceMap(nested['telemetry']);
    if (nestedTelemetry.isNotEmpty) return nestedTelemetry;

    return const <String, dynamic>{};
  }

  String get id =>
      _s(data['id'] ?? data['vehicleId'] ?? data['vehicle_id'] ?? data['uuid']);

  String get name => _s(
    data['name'] ??
        data['vehicleName'] ??
        data['vehicle_name'] ??
        data['title'],
  );

  String get plate => _s(
    data['plateNumber'] ??
        data['plate_number'] ??
        data['plate'] ??
        data['registrationNumber'] ??
        data['registration_number'],
  );

  String get status => _s(data['status'] ?? data['state']);

  bool get isActive {
    final v = data['active'] ?? data['isActive'] ?? data['is_active'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = status.trim().toLowerCase();
    if (s == 'active' || s == 'running') return true;
    if (s == 'inactive' || s == 'disabled') return false;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    return false;
  }

  Map<String, dynamic> get device {
    final d = data['device'];
    if (d is Map) return Map<String, dynamic>.from(d.cast());
    return const <String, dynamic>{};
  }

  Map<String, dynamic> get deviceType {
    final d = device['type'];
    if (d is Map) return Map<String, dynamic>.from(d.cast());
    return const <String, dynamic>{};
  }

  Map<String, dynamic> get vehicleType {
    final t = data['vehicleType'];
    if (t is Map) return Map<String, dynamic>.from(t.cast());
    return const <String, dynamic>{};
  }

  Map<String, dynamic> get plan {
    final p = data['plan'];
    if (p is Map) return Map<String, dynamic>.from(p.cast());
    return const <String, dynamic>{};
  }

  Map<String, dynamic> get userPrimary {
    final u = data['userPrimary'];
    if (u is Map) return Map<String, dynamic>.from(u.cast());
    return const <String, dynamic>{};
  }

  Map<String, dynamic> get userAddedBy {
    final u = data['userAddedBy'];
    if (u is Map) return Map<String, dynamic>.from(u.cast());
    return const <String, dynamic>{};
  }

  Map<String, dynamic> get driver {
    final dv = data['driverVehicle'];
    if (dv is Map) {
      final d = dv['driver'];
      if (d is Map) return Map<String, dynamic>.from(d.cast());
    }
    return const <String, dynamic>{};
  }

  String get model => _s(
    data['model'] ??
        data['deviceModel'] ??
        data['deviceModel'] ??
        deviceType['name'] ??
        deviceType['manufacturer'] ??
        device['model'] ??
        device['typeName'] ??
        data['device'],
  );

  String get type => _s(
    data['type'] ??
        vehicleType['name'] ??
        vehicleType['title'] ??
        vehicleType['slug'] ??
        data['vehicleType'] ??
        data['vehicleTypeName'] ??
        data['vehicle_type_name'],
  );

  String get imei => _s(
    data['imei'] ??
        device['imei'] ??
        data['deviceImei'] ??
        data['device_imei'] ??
        data['imeiNumber'],
  );

  String get simNumber => _s(
    data['simNumber'] ??
        (device['sim'] is Map ? (device['sim'] as Map)['simNumber'] : null) ??
        (device['sim'] is Map ? (device['sim'] as Map)['number'] : null),
  );

  String get simProviderName => _s(
    (device['sim'] is Map && (device['sim'] as Map)['provider'] is Map
        ? ((device['sim'] as Map)['provider'] as Map)['name']
        : null),
  );

  String get gmtOffset =>
      _s(data['gmtOffset'] ?? data['gmt_offset'] ?? data['timezone']);

  String get lastSeen => _s(
    telemetry['lastSeen'] ??
        telemetry['lastSeenAt'] ??
        telemetry['last_seen_at'] ??
        data['lastUpdate'] ??
        data['lastSeen'] ??
        data['lastSeenAt'] ??
        data['last_seen_at'] ??
        data['updatedAt'] ??
        data['updated_at'],
  );

  String get speed => _s(
    telemetry['speed'] ??
        telemetry['currentSpeed'] ??
        data['speed'] ??
        data['currentSpeed'],
  );

  String get ignition => _s(
    telemetry['ignition'] ??
        telemetry['isIgnitionOn'] ??
        telemetry['ignitionStatus'] ??
        data['ignition'] ??
        data['isIgnitionOn'] ??
        data['ignitionStatus'] ??
        device['ignitionSource'],
  );

  String get locationName => _s(
    telemetry['location'] ??
        telemetry['locationName'] ??
        telemetry['address'] ??
        data['location'] ??
        data['locationName'] ??
        data['city'],
  );

  String get vin => _s(data['vin'] ?? data['VIN'] ?? data['chassisNumber']);

  String get primaryExpiry => _s(
    data['primaryExpiry'] ??
        data['primary_expiry'] ??
        data['primaryLicenseExpiry'],
  );

  String get secondaryExpiry => _s(
    data['secondaryExpiry'] ??
        data['secondary_expiry'] ??
        data['secondaryLicenseExpiry'],
  );

  String get engineHours => _s(
    device['engineHours'] ?? telemetry['engineHours'] ?? telemetry['hours'],
  );

  String get odometer =>
      _s(device['odometer'] ?? telemetry['odometer'] ?? telemetry['mileage']);

  String get primaryUserName =>
      _s(userPrimary['name'] ?? userPrimary['fullName']);

  String get primaryUserEmail => _s(userPrimary['email']);

  String get primaryUserUsername =>
      _s(userPrimary['username'] ?? userPrimary['loginType']);

  String get addedByName => _s(userAddedBy['name'] ?? userAddedBy['fullName']);

  String get addedByEmail => _s(userAddedBy['email']);

  String get addedByUsername => _s(userAddedBy['username']);

  String get driverName => _s(driver['name'] ?? driver['fullName']);

  String get driverEmail => _s(driver['email']);

  String get driverPhone =>
      _s(driver['phone'] ?? driver['mobile'] ?? driver['phoneNumber']);

  String get planName => _s(plan['name']);

  String get planPrice => _s(plan['price']);

  String get planCurrency => _s(plan['currency']);

  String get planDurationDays => _s(plan['durationDays']);

  List<Object?>? get usersRaw => _extractList(const [
    'users',
    'userList',
    'vehicleUsers',
    'linkedUsers',
    'assignedUsers',
  ]);

  List<Object?>? get documentsRaw =>
      _extractList(const ['documents', 'docs', 'files']);

  List<VehicleUserItem> get users => usersRaw != null && usersRaw!.isNotEmpty
      ? _mapItems(usersRaw, (map) => VehicleUserItem(map))
      : _synthesizedUsers;

  List<VehicleUserItem> get _synthesizedUsers {
    final out = <VehicleUserItem>[];
    if (userPrimary.isNotEmpty) {
      out.add(
        VehicleUserItem({
          ...userPrimary,
          'role': userPrimary['loginType'] ?? 'USER',
        }),
      );
    }
    if (userAddedBy.isNotEmpty) {
      out.add(
        VehicleUserItem({
          ...userAddedBy,
          'role': userAddedBy['loginType'] ?? 'ADMIN',
        }),
      );
    }
    if (driver.isNotEmpty) {
      out.add(VehicleUserItem({...driver, 'role': driver['role'] ?? 'DRIVER'}));
    }
    return out;
  }

  List<VehicleDocumentItem> get documents =>
      _mapItems(documentsRaw, (map) => VehicleDocumentItem(map));

  List<Object?>? _extractList(List<String> keys) {
    for (final key in keys) {
      final candidate = data[key];
      final list = _coerceList(candidate);
      if (list != null) return list;
    }
    return null;
  }

  static List<Object?>? _coerceList(Object? candidate) {
    if (candidate is List) return List<Object?>.from(candidate);
    if (candidate is Map) {
      for (final k in const ['data', 'items', 'result', 'results', 'list']) {
        final nested = candidate[k];
        if (nested is List) return List<Object?>.from(nested);
      }
    }
    return null;
  }

  static List<T> _mapItems<T>(
    List<Object?>? list,
    T Function(Map<String, dynamic>) builder,
  ) {
    if (list == null) return <T>[];
    final out = <T>[];
    for (final it in list) {
      if (it is Map<String, dynamic>) {
        out.add(builder(it));
      } else if (it is Map) {
        out.add(builder(Map<String, dynamic>.from(it.cast())));
      }
    }
    return out;
  }

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  static Map<String, dynamic> _coerceMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v.cast());
    return const <String, dynamic>{};
  }
}
