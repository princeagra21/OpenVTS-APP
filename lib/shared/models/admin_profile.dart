class AdminProfile {
  final Map<String, dynamic> raw;

  const AdminProfile(this.raw);

  Map<String, dynamic> get data {
    final level1 = raw['data'];
    if (level1 is Map) {
      final l1 = Map<String, dynamic>.from(level1.cast());
      final level2 = l1['data'];
      if (level2 is Map) {
        return Map<String, dynamic>.from(level2.cast());
      }
      return l1;
    }
    return raw;
  }

  List<String> get keys => data.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    data['id'] ??
        data['adminId'] ??
        data['admin_id'] ??
        data['userId'] ??
        data['user_id'] ??
        data['uid'],
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
        data['verifiedStatus'] ??
        data['isActive'],
  );

  bool get isVerified {
    final v =
        data['isVerified'] ??
        data['emailVerified'] ??
        data['isEmailVerified'] ??
        data['verified'] ??
        data['isemailvarified'];
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
    final v =
        data['isActive'] ??
        data['active'] ??
        data['is_active'] ??
        data['status'];
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
    // Some admin profile payloads omit explicit status fields.
    return true;
  }

  String get companyName {
    final direct = _string(data['companyName'] ?? data['company']);
    if (direct.isNotEmpty) return direct;
    final companies = data['companies'];
    if (companies is List && companies.isNotEmpty) {
      final first = companies.first;
      if (first is Map) {
        return _string(first['name'] ?? first['companyName']);
      }
    }
    return '';
  }

  String get website {
    final direct = _string(data['website'] ?? data['domain']);
    if (direct.isNotEmpty) return direct;
    final companies = data['companies'];
    if (companies is List && companies.isNotEmpty) {
      final first = companies.first;
      if (first is Map) {
        return _string(first['websiteUrl'] ?? first['customDomain']);
      }
    }
    return '';
  }

  int get vehiclesCount => _int(
    data['vehicles'] ??
        data['vehicleCount'] ??
        data['vehiclesCount'] ??
        data['vehicles_count'] ??
        data['totalvehicles'],
  );

  int get credits => _int(data['credits'] ?? data['creditBalance']);

  String get createdAt =>
      _string(data['createdAt'] ?? data['created_at'] ?? data['created']);

  String get lastLogin => _string(
    data['lastLogin'] ??
        data['last_login'] ??
        data['lastLoginAt'] ??
        data['recentLogin'] ??
        data['Lastlogin'] ??
        data['updatedAt'] ??
        data['updated_at'],
  );

  String get addressLine {
    // Prefer an explicit address line value. Some APIs also return `address`
    // as an object, which would stringify to "Instance of ..." if read
    // directly, so handle that carefully.
    final direct =
        data['addressLine'] ?? data['address1'] ?? data['address_line'];
    if (direct is String) return direct;

    final addr = data['address'];
    if (addr is String) return addr;
    if (addr is Map) {
      final map = addr is Map<String, dynamic>
          ? addr
          : Map<String, dynamic>.from(addr.cast());
      final nested = map['addressLine'];
      if (nested is String) return nested;
    }
    return '';
  }

  String get city => _string(
    data['cityName'] ??
        data['city'] ??
        (data['address'] is Map ? (data['address'] as Map)['city'] : null) ??
        (data['address'] is Map
            ? (data['address'] as Map)['cityName']
            : null) ??
        (data['address'] is Map ? (data['address'] as Map)['cityId'] : null),
  );
  String get state => _string(
    data['stateName'] ??
        data['state'] ??
        data['stateCode'] ??
        (data['address'] is Map ? (data['address'] as Map)['state'] : null) ??
        (data['address'] is Map
            ? (data['address'] as Map)['stateName']
            : null) ??
        (data['address'] is Map ? (data['address'] as Map)['stateCode'] : null),
  );
  String get country => _string(
    data['countryName'] ??
        data['country'] ??
        data['countryCode'] ??
        (data['address'] is Map
            ? (data['address'] as Map)['country']
            : null) ??
        (data['address'] is Map
            ? (data['address'] as Map)['countryName']
            : null) ??
        (data['address'] is Map
            ? (data['address'] as Map)['countryCode']
            : null),
  );
  String get pincode => _string(
    data['pincode'] ??
        data['postalCode'] ??
        (data['address'] is Map ? (data['address'] as Map)['pincode'] : null),
  );

  String get roleId =>
      _string(data['roleId'] ?? data['role_id'] ?? data['roleID']);

  String get roleName => _string(
    data['role'] ?? data['roleName'] ?? data['userType'] ?? data['type'],
  );

  String get role {
    final fromRole = roleName.trim();
    if (fromRole.isNotEmpty) return fromRole;
    final fromLoginType = _string(
      data['loginType'] ?? data['login_type'],
    ).trim();
    if (fromLoginType.isNotEmpty) return fromLoginType;
    return '—';
  }

  bool get emailVerified => isVerified;

  bool get phoneVerified {
    final candidates = [
      data['phoneVerified'],
      data['isPhoneVerified'],
      data['mobileVerified'],
      data['isMobileVerified'],
      data['isWhatsappVerified'],
      data['isWhatsAppVerified'],
      data['whatsappVerified'],
      data['isWhatsappVarified'],
      data['isMobileVarified'],
    ];
    for (final value in candidates) {
      final parsed = _boolOrNull(value);
      if (parsed != null) return parsed;
    }

    final mobile = data['mobile'];
    if (mobile is Map) {
      final nested = [
        mobile['verified'],
        mobile['isVerified'],
        mobile['isMobileVerified'],
        mobile['isPhoneVerified'],
      ];
      for (final value in nested) {
        final parsed = _boolOrNull(value);
        if (parsed != null) return parsed;
      }
    }

    return false;
  }

  String get phoneDisplay => phone.trim().isEmpty ? '—' : phone.trim();

  String get lastLoginAt => _string(
    data['lastLoginAt'] ??
        data['lastLogin'] ??
        data['last_login'] ??
        data['recentLogin'] ??
        data['updatedAt'] ??
        data['updated_at'],
  );

  String get passwordChangedAt => _string(
    data['passwordChangedAt'] ??
        data['passwordUpdatedAt'] ??
        data['passwordChangeAt'] ??
        data['pwdChangedAt'] ??
        data['updatedAt'] ??
        data['updated_at'],
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

  static bool? _boolOrNull(Object? v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1' || t == 'yes' || t == 'verified') {
        return true;
      }
      if (t == 'false' || t == '0' || t == 'no' || t == 'unverified') {
        return false;
      }
    }
    return null;
  }
}
