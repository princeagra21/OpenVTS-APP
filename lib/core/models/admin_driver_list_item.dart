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

  String get mobilePrefix =>
      _firstString(const ['mobilePrefix', 'phonePrefix', 'countryCode']);

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
    final city = _firstString(const ['city']);
    final state = _firstString(const ['state', 'stateName']);
    final country = _firstString(const ['country', 'countryName']);

    final merged = [
      city,
      state,
      country,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (merged.isNotEmpty) return merged.join(', ');

    return _firstString(const ['address', 'location']);
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
}
