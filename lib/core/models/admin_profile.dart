class AdminProfile {
  final Map<String, dynamic> raw;

  const AdminProfile(this.raw);

  Map<String, dynamic> get data {
    final d = raw['data'];
    if (d is Map) return Map<String, dynamic>.from(d.cast());
    return raw;
  }

  List<String> get keys => data.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    data['id'] ??
        data['adminId'] ??
        data['admin_id'] ??
        data['userId'] ??
        data['user_id'],
  );

  String get fullName =>
      _string(data['name'] ?? data['fullName'] ?? data['full_name']);

  String get username => _string(data['username'] ?? data['handle']);

  String get email => _string(data['email'] ?? data['mail']);

  String get mobilePrefix => _string(data['mobilePrefix'] ?? data['prefix']);

  String get mobileNumber => _string(
    data['mobileNumber'] ??
        data['mobile'] ??
        data['phone'] ??
        data['phoneNumber'],
  );

  String get phone {
    final p = mobilePrefix.trim();
    final n = mobileNumber.trim();
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;
    return '$p$n';
  }

  String get status => _string(
    data['status'] ??
        data['state'] ??
        data['verificationStatus'] ??
        data['verifiedStatus'],
  );

  bool get isVerified {
    final v =
        data['isVerified'] ??
        data['emailVerified'] ??
        data['isEmailVerified'] ??
        data['verified'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    final s = status.trim().toLowerCase();
    if (s.contains('verified')) return true;
    return false;
  }

  bool get isActive {
    final v = data['isActive'] ?? data['active'] ?? data['is_active'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    final s = status.trim().toLowerCase();
    if (s == 'active') return true;
    if (s == 'disabled' || s == 'inactive') return false;
    return false;
  }

  String get companyName => _string(data['companyName'] ?? data['company']);

  String get website => _string(data['website'] ?? data['domain']);

  int get vehiclesCount => _int(
    data['vehicles'] ??
        data['vehicleCount'] ??
        data['vehiclesCount'] ??
        data['vehicles_count'],
  );

  int get credits => _int(data['credits'] ?? data['creditBalance']);

  String get createdAt =>
      _string(data['createdAt'] ?? data['created_at'] ?? data['created']);

  String get lastLogin => _string(
    data['lastLogin'] ??
        data['last_login'] ??
        data['lastLoginAt'] ??
        data['recentLogin'],
  );

  String get addressLine => _string(
    data['addressLine'] ??
        data['address'] ??
        data['address1'] ??
        data['address_line'],
  );

  String get city => _string(data['cityName'] ?? data['city']);
  String get state => _string(data['stateCode'] ?? data['state']);
  String get country => _string(data['countryCode'] ?? data['country']);
  String get pincode => _string(data['pincode'] ?? data['postalCode']);

  String get roleId =>
      _string(data['roleId'] ?? data['role_id'] ?? data['roleID']);

  String get roleName => _string(
    data['role'] ?? data['roleName'] ?? data['userType'] ?? data['type'],
  );

  Object? get permissionsRaw =>
      data['permissions'] ?? data['permission'] ?? data['access'];

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
