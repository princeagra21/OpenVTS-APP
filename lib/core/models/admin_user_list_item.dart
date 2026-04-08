class AdminUserListItem {
  final Map<String, dynamic> raw;

  const AdminUserListItem(this.raw);

  factory AdminUserListItem.fromRaw(Map<String, dynamic> raw) {
    return AdminUserListItem(raw);
  }

  String get id => _firstString(const ['id', 'userId', 'uid']);

  String get fullName {
    final explicit = _firstString(const ['fullName', 'name']);
    if (explicit.isNotEmpty) return explicit;

    final first = _firstString(const ['firstName']);
    final last = _firstString(const ['lastName']);
    final merged = '$first $last'.trim();
    if (merged.isNotEmpty) return merged;

    return _firstString(const ['username', 'email']);
  }

  String get email => _firstString(const ['email', 'emailAddress']);

  String get username => _firstString(const ['username', 'userName']);

  String get phonePrefix =>
      _firstString(const ['mobilePrefix', 'phonePrefix', 'countryCode']);

  String get phoneNumber =>
      _firstString(const ['mobileNumber', 'phoneNumber', 'phone']);

  String get fullPhone {
    final prefix = phonePrefix.trim();
    final number = phoneNumber.trim();
    if (prefix.isNotEmpty && number.isNotEmpty) return '$prefix $number';
    if (number.isNotEmpty) return number;
    return _firstString(const ['phone']);
  }

  bool get isActive {
    final direct = _firstBool(const ['isActive', 'active', 'enabled']);
    if (direct != null) return direct;

    final status = _firstString(const [
      'status',
      'accountStatus',
    ]).toLowerCase();
    if (status.contains('disable') || status.contains('inactive')) return false;
    if (status.contains('active') || status.contains('verify')) return true;
    return false;
  }

  String get statusLabel {
    final status = _firstString(const ['status', 'accountStatus']).trim();
    if (status.isNotEmpty) {
      final lower = status.toLowerCase();
      if (lower.contains('pending')) return 'Pending';
      if (lower.contains('verify')) return 'Verified';
      if (lower.contains('disable') || lower.contains('inactive')) {
        return 'Disabled';
      }
      return status;
    }

    final verified = _firstBool(const ['isVerified', 'emailVerified']);
    if (verified == false) return 'Pending';
    return isActive ? 'Verified' : 'Disabled';
  }

  int get vehiclesCount {
    final direct = _firstInt(const [
      'vehiclesCount',
      'vehicleCount',
      'totalVehicles',
      'vehicles',
    ]);
    return direct ?? 0;
  }

  String get location {
    final address = _asMap(raw['address']);
    final fullAddress = _s(address['fullAddress'] ?? raw['fullAddress']);
    if (fullAddress.isNotEmpty) return fullAddress;

    final city = _firstString(const ['city']);
    final state = _firstString(const ['state', 'stateName']);
    final country = _firstString(const ['country', 'countryName']);

    final parts = <String>[
      city,
      state,
      country,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');

    return _firstString(const ['location', 'address']);
  }

  String get joinedAt =>
      _firstString(const ['joinedAt', 'createdAt', 'createdOn', 'created_at']);

  String get roleLabel {
    final role = _firstString(const ['role', 'roleName', 'userType']);
    final company = _firstNonEmpty([
      _companyNameFromList(),
      _firstString(const ['companyName', 'company', 'tenantName']),
    ]);

    if (company.isNotEmpty && role.isNotEmpty) {
      return '$company • $role';
    }
    if (company.isNotEmpty) return company;
    return role;
  }

  String get initials {
    final name = fullName.trim();
    if (name.isEmpty) return '--';
    final parts = name
        .split(RegExp(r'\\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
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

  int? _firstInt(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
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

  String _companyNameFromList() {
    final list = raw['companies'];
    if (list is! List) return '';
    for (final item in list) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item.cast());
        final name = _s(map['name']);
        if (name.isNotEmpty) return name;
      }
    }
    return '';
  }

  static String _firstNonEmpty(List<String> candidates) {
    for (final value in candidates) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
