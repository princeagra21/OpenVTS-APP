class SuperadminProfile {
  final Map<String, dynamic> raw;

  const SuperadminProfile(this.raw);

  Map<String, dynamic> get _level1 {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return raw;
  }

  Map<String, dynamic> get data {
    final nested = _level1['data'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested.cast());
    return _level1;
  }

  bool? get action => _bool(_level1['action']);

  String get id => _string(
    data['id'] ??
        data['uid'] ??
        data['userId'] ??
        data['user_id'] ??
        data['adminId'] ??
        data['admin_id'],
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

  String get roleName => _string(
    data['role'] ?? data['roleName'] ?? data['userType'] ?? data['type'],
  );

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

  bool? get isActive {
    final explicit =
        data['isActive'] ??
        data['active'] ??
        data['is_active'] ??
        data['status'] ??
        data['state'];
    final parsed = _bool(explicit);
    if (parsed != null) return parsed;
    return action;
  }

  bool? get isVerified {
    final v =
        data['isVerified'] ??
        data['emailVerified'] ??
        data['isEmailVerified'] ??
        data['verified'] ??
        data['isemailvarified'];
    return _bool(v);
  }

  Map<String, dynamic> get company {
    final companies = data['companies'];
    if (companies is List && companies.isNotEmpty) {
      final first = companies.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first.cast());
    }
    return const <String, dynamic>{};
  }

  String get companyName {
    final direct = _string(data['companyName'] ?? data['company']);
    if (direct.isNotEmpty) return direct;
    return _string(company['name'] ?? company['companyName']);
  }

  String get website {
    final direct = _string(data['website'] ?? data['domain']);
    if (direct.isNotEmpty) return direct;
    return _string(company['websiteUrl'] ?? company['customDomain']);
  }

  Map<String, dynamic> get address {
    final a = data['address'];
    if (a is Map<String, dynamic>) return a;
    if (a is Map) return Map<String, dynamic>.from(a.cast());
    return const <String, dynamic>{};
  }

  String get addressLine => _string(
    data['addressLine'] ??
        data['address'] ??
        data['address1'] ??
        data['address_line'] ??
        address['addressLine'],
  );

  String get city => _string(
    data['cityName'] ??
        data['city'] ??
        address['city'] ??
        address['cityName'] ??
        address['cityId'],
  );

  String get state => _string(
    data['stateCode'] ??
        data['state'] ??
        address['state'] ??
        address['stateCode'],
  );

  String get country =>
      _string(data['countryCode'] ?? data['country'] ?? address['countryCode']);

  String get pincode =>
      _string(data['pincode'] ?? data['postalCode'] ?? address['pincode']);

  List<String> get socialLabels {
    final links = company['socialLinks'];
    if (links is! Map) return const <String>[];

    final out = <String>[];
    links.forEach((key, value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return;
      final label = _titleCaseKey(key.toString());
      if (label.isEmpty) return;
      out.add(label);
    });
    out.sort();
    return out;
  }

  static String _titleCaseKey(String key) {
    final clean = key.replaceAll('_', ' ').trim();
    if (clean.isEmpty) return '';
    return clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  static String _string(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static bool? _bool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (const {'true', '1', 'yes', 'y', 'active', 'enabled'}.contains(text)) {
      return true;
    }
    if (const {
      'false',
      '0',
      'no',
      'n',
      'inactive',
      'disabled',
    }.contains(text)) {
      return false;
    }
    return null;
  }
}
