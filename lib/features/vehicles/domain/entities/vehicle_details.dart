import 'package:open_vts/features/vehicles/domain/entities/vehicle_document_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_user_item.dart';

class VehicleDetails {
  VehicleDetails(Object? source)
      : this.typed(
          id: _readString(_vehicleMap(source), const ['id', 'vehicleId', 'vehicle_id', 'uuid']),
          name: _readString(_vehicleMap(source), const ['name', 'vehicleName', 'vehicle_name', 'title']),
          plate: _readString(_vehicleMap(source), const ['plateNumber', 'plate_number', 'plate', 'registrationNumber', 'registration_number']),
          status: _readString(_vehicleMap(source), const ['status', 'state']),
          isActive: _readBool(_vehicleMap(source), const ['active', 'isActive', 'is_active']) ?? _statusIsActive(_readString(_vehicleMap(source), const ['status', 'state'])),
          device: VehicleDeviceInfo.fromObject(_nested(_vehicleMap(source), 'device')),
          vehicleType: VehicleTypeInfo.fromObject(_nested(_vehicleMap(source), 'vehicleType')),
          plan: VehiclePlanInfo.fromObject(_nested(_vehicleMap(source), 'plan')),
          primaryUser: VehicleUserItem(_nested(_vehicleMap(source), 'userPrimary')),
          addedByUser: VehicleUserItem(_nested(_vehicleMap(source), 'userAddedBy')),
          driver: VehicleUserItem(_driverSource(_vehicleMap(source))),
          gmtOffset: _readString(_vehicleMap(source), const ['gmtOffset', 'gmt_offset', 'timezone']),
          telemetry: VehicleTelemetryInfo.fromObject(_telemetryMap(source)),
          vin: _readString(_vehicleMap(source), const ['vin', 'VIN', 'chassisNumber']),
          primaryExpiry: _readString(_vehicleMap(source), const ['primaryExpiry', 'primary_expiry', 'primaryLicenseExpiry']),
          secondaryExpiry: _readString(_vehicleMap(source), const ['secondaryExpiry', 'secondary_expiry', 'secondaryLicenseExpiry']),
          users: _buildUsers(source),
          documents: _buildDocuments(source),
        );

  const VehicleDetails.typed({
    required this.id,
    required this.name,
    required this.plate,
    required this.status,
    required this.isActive,
    required this.device,
    required this.vehicleType,
    required this.plan,
    required this.primaryUser,
    required this.addedByUser,
    required this.driver,
    required this.gmtOffset,
    required this.telemetry,
    required this.vin,
    required this.primaryExpiry,
    required this.secondaryExpiry,
    required this.users,
    required this.documents,
  });

  final String id;
  final String name;
  final String plate;
  final String status;
  final bool isActive;
  final VehicleDeviceInfo device;
  final VehicleTypeInfo vehicleType;
  final VehiclePlanInfo plan;
  final VehicleUserItem primaryUser;
  final VehicleUserItem addedByUser;
  final VehicleUserItem driver;
  final String gmtOffset;
  final VehicleTelemetryInfo telemetry;
  final String vin;
  final String primaryExpiry;
  final String secondaryExpiry;
  final List<VehicleUserItem> users;
  final List<VehicleDocumentItem> documents;

  Map<String, Object?> get data => <String, Object?>{
        'id': id,
        'name': name,
        'vehicleName': name,
        'plateNumber': plate,
        'status': status,
        'isActive': isActive,
        'imei': imei,
        'simNumber': simNumber,
        'gmtOffset': gmtOffset,
        'lastSeen': lastSeen,
        'speed': speed,
        'ignition': ignition,
        'locationName': locationName,
        'latitude': telemetry.latitude,
        'longitude': telemetry.longitude,
        'vin': vin,
        'primaryExpiry': primaryExpiry,
        'secondaryExpiry': secondaryExpiry,
        'engineHours': engineHours,
        'odometer': odometer,
        'device': device.asMap,
        'vehicleType': vehicleType.asMap,
        'plan': plan.asMap,
        'userPrimary': primaryUserAsMap,
        'userAddedBy': addedByUserAsMap,
        'driver': driverAsMap,
      };

  Map<String, Object?> get raw => data;
  Map<String, Object?> get primaryUserAsMap => <String, Object?>{
        'id': primaryUser.id,
        'name': primaryUser.name,
        'username': primaryUser.username,
        'email': primaryUser.email,
        'phone': primaryUser.phone,
        'role': primaryUser.role,
      };
  Map<String, Object?> get addedByUserAsMap => <String, Object?>{
        'id': addedByUser.id,
        'name': addedByUser.name,
        'username': addedByUser.username,
        'email': addedByUser.email,
        'phone': addedByUser.phone,
        'role': addedByUser.role,
      };
  Map<String, Object?> get driverAsMap => <String, Object?>{
        'id': driver.id,
        'name': driver.name,
        'username': driver.username,
        'email': driver.email,
        'phone': driver.phone,
        'role': driver.role,
      };

  String get model {
    if (device.model.isNotEmpty) return device.model;
    if (device.typeName.isNotEmpty) return device.typeName;
    if (device.type.name.isNotEmpty) return device.type.name;
    if (device.type.manufacturer.isNotEmpty) return device.type.manufacturer;
    return '';
  }

  String get type {
    if (vehicleType.name.isNotEmpty) return vehicleType.name;
    if (vehicleType.title.isNotEmpty) return vehicleType.title;
    return vehicleType.slug;
  }

  String get imei => device.imei;
  String get simNumber => device.simNumber;
  String get simProviderName => device.simProviderName;
  String get lastSeen => telemetry.lastSeen;
  String get speed => telemetry.speed;
  String get ignition => telemetry.ignition.isNotEmpty ? telemetry.ignition : device.ignitionSource;
  String get locationName => telemetry.locationName;
  String get engineHours => device.engineHours.isNotEmpty ? device.engineHours : telemetry.engineHours;
  String get odometer => device.odometer.isNotEmpty ? device.odometer : telemetry.odometer;

  String get primaryUserName => primaryUser.name;
  String get primaryUserEmail => primaryUser.email;
  String get primaryUserUsername => primaryUser.username;
  String get addedByName => addedByUser.name;
  String get addedByEmail => addedByUser.email;
  String get addedByUsername => addedByUser.username;
  String get driverName => driver.name;
  String get driverEmail => driver.email;
  String get driverPhone => driver.phone;
  String get planName => plan.name;
  String get planPrice => plan.price;
  String get planCurrency => plan.currency;
  String get planDurationDays => plan.durationDays;

  List<Object?>? get usersRaw => users.isEmpty ? null : List<Object?>.from(users);
  List<Object?>? get documentsRaw => documents.isEmpty ? null : List<Object?>.from(documents);

  static Map<String, Object?> _objectMap(Object? value) {
    if (value is Map) {
      return <String, Object?>{for (final e in value.entries) e.key.toString(): e.value};
    }
    return const <String, Object?>{};
  }

  static Map<String, Object?> _payloadMap(Object? source) {
    final root = _objectMap(source);
    final data = _objectMap(root['data']);
    return data.isNotEmpty ? data : root;
  }

  static Map<String, Object?> _vehicleMap(Object? source) {
    final root = _payloadMap(source);
    final vehicle = _objectMap(root['vehicle']);
    if (vehicle.isNotEmpty) return vehicle;
    final nested = _objectMap(root['data']);
    final nestedVehicle = _objectMap(nested['vehicle']);
    if (nestedVehicle.isNotEmpty) return nestedVehicle;
    if (nested.isNotEmpty) return nested;
    return root;
  }

  static Map<String, Object?> _telemetryMap(Object? source) {
    final root = _payloadMap(source);
    final telemetry = _objectMap(root['telemetry']);
    if (telemetry.isNotEmpty) return telemetry;
    final nested = _objectMap(root['data']);
    final nestedTelemetry = _objectMap(nested['telemetry']);
    if (nestedTelemetry.isNotEmpty) return nestedTelemetry;
    return const <String, Object?>{};
  }

  static Object? _nested(Map<String, Object?> map, String key) => map[key];

  static Object? _driverSource(Map<String, Object?> map) {
    final driverVehicle = _objectMap(map['driverVehicle']);
    final driver = _objectMap(driverVehicle['driver']);
    return driver.isNotEmpty ? driver : const <String, Object?>{};
  }

  static List<VehicleUserItem> _buildUsers(Object? source) {
    final data = _vehicleMap(source);
    final list = _extractList(data, const ['users', 'userList', 'vehicleUsers', 'linkedUsers', 'assignedUsers']);
    if (list.isNotEmpty) return list.map(VehicleUserItem.new).toList(growable: false);
    final primary = VehicleUserItem(data['userPrimary']);
    final addedBy = VehicleUserItem(data['userAddedBy']);
    final driver = VehicleUserItem(_driverSource(data));
    return <VehicleUserItem>[
      if (primary.id.isNotEmpty || primary.name.isNotEmpty || primary.email.isNotEmpty) primary,
      if (addedBy.id.isNotEmpty || addedBy.name.isNotEmpty || addedBy.email.isNotEmpty) addedBy,
      if (driver.id.isNotEmpty || driver.name.isNotEmpty || driver.email.isNotEmpty) driver,
    ];
  }

  static List<VehicleDocumentItem> _buildDocuments(Object? source) {
    final data = _vehicleMap(source);
    final list = _extractList(data, const ['documents', 'docs', 'files']);
    return list.map(VehicleDocumentItem.new).toList(growable: false);
  }

  static List<Object?> _extractList(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final list = _coerceList(map[key]);
      if (list.isNotEmpty) return list;
    }
    return const <Object?>[];
  }

  static List<Object?> _coerceList(Object? value) {
    if (value is List) return List<Object?>.from(value);
    final map = _objectMap(value);
    for (final key in const ['data', 'items', 'result', 'results', 'list']) {
      final nested = map[key];
      if (nested is List) return List<Object?>.from(nested);
    }
    return const <Object?>[];
  }

  static String _readString(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static bool? _readBool(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value?.toString().trim().toLowerCase() ?? '';
      if (text == 'true' || text == '1' || text == 'yes' || text == 'active' || text == 'running') return true;
      if (text == 'false' || text == '0' || text == 'no' || text == 'inactive' || text == 'disabled') return false;
    }
    return null;
  }

  static bool _statusIsActive(String status) {
    final text = status.trim().toLowerCase();
    return text == 'active' || text == 'running';
  }
}

class VehicleDeviceInfo {
  VehicleDeviceInfo.fromObject(Object? source)
      : id = _readString(source, const ['id', 'deviceId', 'device_id']),
        imei = _readString(source, const ['imei', 'deviceImei', 'device_imei', 'imeiNumber']),
        model = _readString(source, const ['model', 'deviceModel']),
        typeName = _readString(source, const ['typeName', 'type_name']),
        ignitionSource = _readString(source, const ['ignitionSource']),
        engineHours = _readString(source, const ['engineHours']),
        odometer = _readString(source, const ['odometer']),
        simNumber = _readSimNumber(source),
        simProviderName = _readSimProviderName(source),
        type = VehicleDeviceTypeInfo.fromObject(_objectMap(source)['type']);

  const VehicleDeviceInfo.typed({
    required this.id,
    required this.imei,
    required this.model,
    required this.typeName,
    required this.ignitionSource,
    required this.engineHours,
    required this.odometer,
    required this.simNumber,
    required this.simProviderName,
    required this.type,
  });

  final String id;
  final String imei;
  final String model;
  final String typeName;
  final String ignitionSource;
  final String engineHours;
  final String odometer;
  final String simNumber;
  final String simProviderName;
  final VehicleDeviceTypeInfo type;

  Map<String, Object?> get asMap => <String, Object?>{
        'id': id,
        'imei': imei,
        'model': model,
        'typeName': typeName,
        'ignitionSource': ignitionSource,
        'engineHours': engineHours,
        'odometer': odometer,
        'simNumber': simNumber,
        'sim': <String, Object?>{'simNumber': simNumber, 'provider': <String, Object?>{'name': simProviderName}},
        'type': type.asMap,
      };

  static Map<String, Object?> _objectMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final e in value.entries) e.key.toString(): e.value};
    return const <String, Object?>{};
  }

  static String _readString(Object? source, List<String> keys) {
    final map = _objectMap(source);
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static String _readSimNumber(Object? source) {
    final map = _objectMap(source);
    final sim = _objectMap(map['sim']);
    return _readString(map, const ['simNumber'])
        .isNotEmpty ? _readString(map, const ['simNumber']) : _readString(sim, const ['simNumber', 'number']);
  }

  static String _readSimProviderName(Object? source) {
    final sim = _objectMap(_objectMap(source)['sim']);
    final provider = _objectMap(sim['provider']);
    return _readString(provider, const ['name']);
  }
}

class VehicleDeviceTypeInfo {
  VehicleDeviceTypeInfo.fromObject(Object? source)
      : name = _readString(source, const ['name', 'title', 'type']),
        manufacturer = _readString(source, const ['manufacturer', 'brand']);

  const VehicleDeviceTypeInfo.typed({required this.name, required this.manufacturer});

  final String name;
  final String manufacturer;

  Map<String, Object?> get asMap => <String, Object?>{'name': name, 'manufacturer': manufacturer};

  static String _readString(Object? source, List<String> keys) {
    if (source is! Map) return '';
    final map = <String, Object?>{for (final e in source.entries) e.key.toString(): e.value};
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}

class VehicleTypeInfo {
  VehicleTypeInfo.fromObject(Object? source)
      : name = _readString(source, const ['name']),
        title = _readString(source, const ['title']),
        slug = _readString(source, const ['slug', 'type', 'label']);

  const VehicleTypeInfo.typed({required this.name, required this.title, required this.slug});

  final String name;
  final String title;
  final String slug;

  Map<String, Object?> get asMap => <String, Object?>{'name': name, 'title': title, 'slug': slug};

  static String _readString(Object? source, List<String> keys) {
    if (source is! Map) return source?.toString().trim() ?? '';
    final map = <String, Object?>{for (final e in source.entries) e.key.toString(): e.value};
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}

class VehiclePlanInfo {
  VehiclePlanInfo.fromObject(Object? source)
      : name = _readString(source, const ['name']),
        price = _readString(source, const ['price']),
        currency = _readString(source, const ['currency']),
        durationDays = _readString(source, const ['durationDays', 'duration_days']);

  const VehiclePlanInfo.typed({required this.name, required this.price, required this.currency, required this.durationDays});

  final String name;
  final String price;
  final String currency;
  final String durationDays;

  Map<String, Object?> get asMap => <String, Object?>{'name': name, 'price': price, 'currency': currency, 'durationDays': durationDays};

  static String _readString(Object? source, List<String> keys) {
    if (source is! Map) return '';
    final map = <String, Object?>{for (final e in source.entries) e.key.toString(): e.value};
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}

class VehicleTelemetryInfo {
  VehicleTelemetryInfo.fromObject(Object? source)
      : lastSeen = _readString(source, const ['lastSeen', 'lastSeenAt', 'last_seen_at', 'lastUpdate', 'updatedAt', 'updated_at']),
        speed = _readString(source, const ['speed', 'currentSpeed']),
        ignition = _readString(source, const ['ignition', 'isIgnitionOn', 'ignitionStatus']),
        locationName = _readString(source, const ['location', 'locationName', 'address', 'city']),
        engineHours = _readString(source, const ['engineHours', 'hours']),
        odometer = _readString(source, const ['odometer', 'mileage']),
        latitude = _readString(source, const ['latitude', 'lat', 'locationLat', 'location_lat']),
        longitude = _readString(source, const ['longitude', 'lng', 'lon', 'locationLng', 'location_lng']);

  const VehicleTelemetryInfo.typed({required this.lastSeen, required this.speed, required this.ignition, required this.locationName, required this.engineHours, required this.odometer, required this.latitude, required this.longitude});

  final String lastSeen;
  final String speed;
  final String ignition;
  final String locationName;
  final String engineHours;
  final String odometer;
  final String latitude;
  final String longitude;

  Map<String, Object?> get asMap => <String, Object?>{
        'lastSeen': lastSeen,
        'lastSeenAt': lastSeen,
        'speed': speed,
        'speedKph': speed,
        'currentSpeed': speed,
        'ignition': ignition,
        'isIgnitionOn': ignition,
        'ignitionStatus': ignition,
        'location': locationName,
        'locationName': locationName,
        'address': locationName,
        'engineHours': engineHours,
        'engineHoursToday': engineHours,
        'totalengineHours': engineHours,
        'odometer': odometer,
        'mileage': odometer,
        'latitude': latitude,
        'lat': latitude,
        'longitude': longitude,
        'lng': longitude,
        'status': '',
        'motion': '',
        'satellites': '',
        'satellite': '',
      };

  Object? operator [](String key) => asMap[key];

  static String _readString(Object? source, List<String> keys) {
    if (source is! Map) return '';
    final map = <String, Object?>{for (final e in source.entries) e.key.toString(): e.value};
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}
