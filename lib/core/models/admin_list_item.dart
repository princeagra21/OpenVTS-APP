class AdminListItem {
  final Map<String, dynamic> raw;

  const AdminListItem(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['adminId'] ??
        raw['admin_id'] ??
        raw['userId'] ??
        raw['user_id'],
  );

  String get name =>
      _string(raw['name'] ?? raw['fullName'] ?? raw['full_name']);

  String get username => _string(raw['username'] ?? raw['handle']);

  String get email => _string(raw['email'] ?? raw['mail']);

  String get phone => _string(
    raw['mobileNumber'] ?? raw['mobile'] ?? raw['phone'] ?? raw['phoneNumber'],
  );

  String get status => _string(
    raw['status'] ??
        raw['state'] ??
        raw['verificationStatus'] ??
        raw['verifiedStatus'],
  );

  bool get isActive {
    final v = raw['isActive'] ?? raw['active'] ?? raw['is_active'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    final s = status.trim().toLowerCase();
    if (s == 'active' || s == 'verified') return true;
    if (s == 'disabled' || s == 'inactive') return false;
    return false;
  }

  int get vehiclesCount => _int(
    raw['vehicles'] ??
        raw['vehicleCount'] ??
        raw['vehiclesCount'] ??
        raw['vehicles_count'],
  );

  int get credits => _int(raw['credits'] ?? raw['creditBalance']);

  String get role =>
      _string(raw['role'] ?? raw['roleName'] ?? raw['role_name']);

  String get location =>
      _string(raw['location'] ?? raw['city'] ?? raw['state']);

  String get recentLogin => _string(
    raw['recentLogin'] ??
        raw['lastLogin'] ??
        raw['last_login'] ??
        raw['lastLoginAt'],
  );

  String get createdAt => _string(raw['createdAt'] ?? raw['created_at']);

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  static int _int(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return int.tryParse(cleaned) ?? 0;
    }
    return int.tryParse(v.toString()) ?? 0;
  }
}
