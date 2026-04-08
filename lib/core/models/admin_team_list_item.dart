class AdminTeamListItem {
  final Map<String, dynamic> raw;

  const AdminTeamListItem(this.raw);

  factory AdminTeamListItem.fromRaw(Map<String, dynamic> raw) {
    return AdminTeamListItem(raw);
  }

  String get id => _firstString(const ['id', 'uid', 'userId', '_id']);

  String get fullName => _firstString(const ['name', 'fullName']);

  String get username => _firstString(const ['username', 'userName']);

  String get email => _firstString(const ['email', 'emailAddress']);

  String get mobilePrefix =>
      _firstString(const ['mobilePrefix', 'mobileCode', 'phonePrefix']);

  String get mobileNumber =>
      _firstString(const ['mobileNumber', 'mobile', 'phoneNumber', 'phone']);

  String get fullPhone {
    final prefix = mobilePrefix.trim();
    final number = mobileNumber.trim();
    if (prefix.isNotEmpty && number.isNotEmpty) return '$prefix $number';
    return number;
  }

  bool get isActive {
    final direct = _firstBool(const ['isActive', 'active', 'enabled']);
    return direct ?? false;
  }

  String get statusLabel => isActive ? 'Active' : 'Inactive';

  String get joinedAt =>
      _firstString(const ['createdAt', 'joinedAt', 'created_on', 'created_at']);

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
