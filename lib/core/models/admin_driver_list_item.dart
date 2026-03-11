class AdminDriverListItem {
  final Map<String, dynamic> raw;

  const AdminDriverListItem(this.raw);

  factory AdminDriverListItem.fromRaw(Map<String, dynamic> raw) {
    return AdminDriverListItem(raw);
  }

  String get id => _firstString(const ['id', 'driverId', 'uid', '_id']);

  String get fullName {
    final explicit = _firstString(const ['fullName', 'name']);
    if (explicit.isNotEmpty) return explicit;

    final first = _firstString(const ['firstName']);
    final last = _firstString(const ['lastName']);
    final merged = '$first $last'.trim();
    if (merged.isNotEmpty) return merged;

    return _firstString(const ['username', 'email']);
  }

  String get username => _firstString(const ['username', 'userName']);

  String get email => _firstString(const ['email', 'emailAddress']);

  String get mobilePrefix => _firstString(const [
    'mobilePrefix',
    'mobileCode',
    'phonePrefix',
    'countryCode',
  ]);

  String get mobileNumber =>
      _firstString(const ['mobile', 'mobileNumber', 'phoneNumber', 'phone']);

  String get fullPhone {
    final prefix = mobilePrefix.trim();
    final number = mobileNumber.trim();
    if (prefix.isNotEmpty && number.isNotEmpty) return '$prefix $number';
    return number;
  }

  bool get isActive {
    final direct = _firstBool(const [
      'isActive',
      'isactive',
      'active',
      'enabled',
    ]);
    if (direct != null) return direct;

    final normalized = normalizeStatus(rawStatus);
    if (normalized == 'inactive') return false;
    if (normalized == 'active') return true;
    return false;
  }

  String get rawStatus =>
      _firstString(const ['status', 'accountStatus', 'state', 'driverStatus']);

  String get statusLabel {
    final normalized = normalizeStatus(rawStatus, isActive: isActive);
    if (normalized == 'pending') return 'Pending';
    if (normalized == 'inactive') return 'Inactive';
    if (normalized == 'active') return 'Active';
    return rawStatus.isEmpty ? 'Inactive' : rawStatus;
  }

  String get addressLocation {
    final city = _nestedString(
      const ['city', 'cityId'],
      nestedKeys: const ['address'],
    );
    final state = _nestedString(
      const ['state', 'stateName', 'stateCode'],
      nestedKeys: const ['address'],
    );
    final country = _nestedString(
      const ['country', 'countryName', 'countryCode'],
      nestedKeys: const ['address'],
    );

    final merged = [
      city,
      state,
      country,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (merged.isNotEmpty) return merged.join(', ');

    return _nestedString(
      const ['fullAddress', 'addressLine'],
      nestedKeys: const ['address'],
      fallbackKeys: const ['address', 'location'],
    );
  }

  String get lastActivityAt => _firstString(const [
    'lastActivityAt',
    'last_activity',
    'lastSeenAt',
    'lastSeen',
    'updatedAt',
    'timestamp',
  ]);

  String get expiryDate => _firstString(const [
    'expiry',
    'expiryDate',
    'licenseExpiry',
    'planExpiry',
  ]);

  String get driverVehicleLabel {
    final nested = raw['driverVehicle'];
    if (nested is Map<String, dynamic>) {
      final vehicleNode = nested['vehicle'] is Map
          ? Map<String, dynamic>.from((nested['vehicle'] as Map).cast())
          : nested;
      final vehicleType = vehicleNode['vehicleType'];
      final typeName = vehicleType is Map
          ? _cleanText(
              vehicleType['name'] ??
                  vehicleType['title'] ??
                  vehicleType['type'] ??
                  vehicleType['slug'],
            )
          : '';
      final base = _cleanText(
        vehicleNode['plateNumber'] ??
            vehicleNode['name'] ??
            vehicleNode['vehicleName'] ??
            vehicleNode['plate'] ??
            vehicleNode['registrationNumber'],
      );
      if (base.isNotEmpty && typeName.isNotEmpty) return '$base • $typeName';
      if (base.isNotEmpty) return base;
      if (typeName.isNotEmpty) return typeName;
    } else if (nested is Map) {
      final map = Map<String, dynamic>.from(nested.cast());
      final vehicleNode = map['vehicle'] is Map
          ? Map<String, dynamic>.from((map['vehicle'] as Map).cast())
          : map;
      final vehicleType = vehicleNode['vehicleType'];
      final typeName = vehicleType is Map
          ? _cleanText(
              vehicleType['name'] ??
                  vehicleType['title'] ??
                  vehicleType['type'] ??
                  vehicleType['slug'],
            )
          : '';
      final base = _cleanText(
        vehicleNode['plateNumber'] ??
            vehicleNode['name'] ??
            vehicleNode['vehicleName'] ??
            vehicleNode['plate'] ??
            vehicleNode['registrationNumber'],
      );
      if (base.isNotEmpty && typeName.isNotEmpty) return '$base • $typeName';
      if (base.isNotEmpty) return base;
      if (typeName.isNotEmpty) return typeName;
    }

    final direct = _firstString(const [
      'driverVehicleName',
      'assignedVehicleName',
      'vehicleName',
      'vehicle',
    ]);
    if (direct.isNotEmpty) return direct;

    final directType = _firstString(const [
      'driverVehicleType',
      'vehicleTypeName',
      'vehicleType',
      'type',
    ]);
    return directType;
  }

  String get primaryUserId {
    final nested = raw['userPrimary'];
    if (nested is Map) {
      final uid = nested['uid'] ?? nested['id'] ?? nested['userId'];
      final text = _cleanText(uid);
      if (text.isNotEmpty) return text;
    }
    return _firstString(const ['primaryUserId', 'primaryUserid']);
  }

  String get primaryUserName {
    final nested = raw['userPrimary'];
    if (nested is Map) {
      final text = _cleanText(
        nested['name'] ?? nested['fullName'] ?? nested['username'],
      );
      if (text.isNotEmpty) return text;
    }
    return _firstString(const ['primaryUserName', 'userName', 'ownerName']);
  }

  String get initials {
    final name = fullName.trim();
    if (name.isEmpty) return '--';

    final parts = name
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  static String normalizeStatus(String? raw, {bool? isActive}) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) {
      if (isActive == true) return 'active';
      if (isActive == false) return 'inactive';
      return '';
    }

    if (value == 'enabled' || value == 'verified' || value == 'verify') {
      return 'active';
    }
    if (value == 'disabled' || value == 'disable' || value == 'inactive') {
      return 'inactive';
    }
    if (value == 'pending') return 'pending';

    if (value.contains('enable') ||
        value.contains('activ') ||
        value.contains('verify')) {
      return 'active';
    }
    if (value.contains('inactiv') || value.contains('disable')) {
      return 'inactive';
    }
    if (value.contains('pend')) return 'pending';

    return value;
  }

  String _firstString(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final s = value.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }
    return '';
  }

  bool? _firstBool(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final s = value.toString().trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return null;
  }

  String _cleanText(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  String _nestedString(
    List<String> keys, {
    required List<String> nestedKeys,
    List<String> fallbackKeys = const <String>[],
  }) {
    for (final nestedKey in nestedKeys) {
      final nested = raw[nestedKey];
      if (nested is Map<String, dynamic>) {
        for (final key in keys) {
          final value = nested[key];
          final text = _cleanText(value);
          if (text.isNotEmpty) return text;
        }
      } else if (nested is Map) {
        final map = Map<String, dynamic>.from(nested.cast());
        for (final key in keys) {
          final value = map[key];
          final text = _cleanText(value);
          if (text.isNotEmpty) return text;
        }
      }
    }

    for (final key in fallbackKeys) {
      final value = raw[key];
      final text = _cleanText(value);
      if (text.isNotEmpty) return text;
    }

    return '';
  }
}
