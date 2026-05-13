class SuperadminProfile {
  SuperadminProfile(Object? source)
      : this.typed(
          action: _bool(_level1(source)['action']),
          id: _stringFrom(_data(source), const ['id', 'uid', 'userId', 'user_id', 'adminId', 'admin_id']),
          fullName: _stringFrom(_data(source), const ['name', 'fullName', 'full_name']),
          username: _stringFrom(_data(source), const ['username', 'handle']),
          email: _stringFrom(_data(source), const ['email', 'mail']),
          mobilePrefix: _stringFrom(_data(source), const ['mobilePrefix', 'prefix']),
          mobileNumber: _stringFrom(_data(source), const ['mobileNumber', 'mobile', 'phone', 'phoneNumber']),
          roleName: _stringFrom(_data(source), const ['role', 'roleName', 'userType', 'type']),
          createdAt: _stringFrom(_data(source), const ['createdAt', 'created_at', 'created']),
          lastLogin: _stringFrom(_data(source), const ['lastLogin', 'last_login', 'lastLoginAt', 'recentLogin', 'Lastlogin', 'updatedAt', 'updated_at']),
          isActive: _bool(_firstValue(_data(source), const ['isActive', 'active', 'is_active', 'status', 'state'])) ?? _bool(_level1(source)['action']),
          isVerified: _bool(_firstValue(_data(source), const ['isVerified', 'emailVerified', 'isEmailVerified', 'verified', 'isemailvarified'])),
          companyInfo: SuperadminCompanyInfo.fromObject(_companySource(source)),
          addressInfo: SuperadminAddressInfo.fromObject(_addressSource(source)),
        );

  const SuperadminProfile.typed({
    required this.action,
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.roleName,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
    required this.isVerified,
    required this.companyInfo,
    required this.addressInfo,
  });

  final bool? action;
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String roleName;
  final String createdAt;
  final String lastLogin;
  final bool? isActive;
  final bool? isVerified;
  final SuperadminCompanyInfo companyInfo;
  final SuperadminAddressInfo addressInfo;


  Map<String, Object?> get raw => data;

  Map<String, Object?> get data => <String, Object?>{
        'id': id,
        'name': fullName,
        'fullName': fullName,
        'username': username,
        'email': email,
        'mobilePrefix': mobilePrefix,
        'mobileNumber': mobileNumber,
        'roleName': roleName,
        'createdAt': createdAt,
        'lastLogin': lastLogin,
        'isActive': isActive,
        'isVerified': isVerified,
        'companyName': companyInfo.name,
        'website': companyInfo.website,
        'companies': <Object?>[companyInfo.asMap],
        'address': addressInfo.asMap,
      };

  Map<String, Object?> get company => companyInfo.asMap;
  Map<String, Object?> get companyMap => companyInfo.asMap;
  Map<String, Object?> get companyData => companyInfo.asMap;
  Map<String, Object?> get address => addressInfo.asMap;
  Map<String, Object?> get addressMap => addressInfo.asMap;
  String get lastLoginAt => lastLogin;
  bool? get emailVerified => isVerified;
  bool? get phoneVerified => isVerified;

  String get phone {
    final p = mobilePrefix.trim();
    final n = mobileNumber.trim();
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;
    return '$p$n';
  }

  String get companyName => companyInfo.name;
  String get website => companyInfo.website;
  String get addressLine => addressInfo.addressLine;
  String get city => addressInfo.city;
  String get state => addressInfo.state;
  String get country => addressInfo.country;
  String get pincode => addressInfo.pincode;
  List<String> get socialLabels => companyInfo.socialLabels;

  static Map<String, Object?> _level1(Object? source) {
    final root = _asMap(source);
    final data = _asMap(root['data']);
    return data.isNotEmpty ? data : root;
  }

  static Map<String, Object?> _data(Object? source) {
    final level1 = _level1(source);
    final nested = _asMap(level1['data']);
    return nested.isNotEmpty ? nested : level1;
  }

  static Object? _companySource(Object? source) {
    final data = _data(source);
    final companies = data['companies'];
    if (companies is List && companies.isNotEmpty) return companies.first;
    final direct = <String, Object?>{
      'name': data['companyName'] ?? data['company'],
      'websiteUrl': data['website'] ?? data['domain'],
    };
    return direct;
  }

  static Object? _addressSource(Object? source) {
    final data = _data(source);
    final address = _asMap(data['address']);
    if (address.isNotEmpty) return address;
    return <String, Object?>{
      'addressLine': data['addressLine'] ?? data['address1'] ?? data['address_line'] ?? (data['address'] is String ? data['address'] : ''),
      'city': data['cityName'] ?? data['city'],
      'state': data['stateCode'] ?? data['state'],
      'country': data['countryCode'] ?? data['country'],
      'pincode': data['pincode'] ?? data['postalCode'],
    };
  }

  static Object? _firstValue(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) return map[key];
    }
    return null;
  }

  static String _stringFrom(Map<String, Object?> map, List<String> keys) {
    final value = _firstValue(map, keys);
    if (value == null) return '';
    return value.toString().trim();
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static bool? _bool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (const {'true', '1', 'yes', 'y', 'active', 'enabled'}.contains(text)) return true;
    if (const {'false', '0', 'no', 'n', 'inactive', 'disabled'}.contains(text)) return false;
    return null;
  }
}

class SuperadminCompanyInfo {
  SuperadminCompanyInfo.fromObject(Object? source)
      : name = _stringFrom(_asMap(source), const ['name', 'companyName']),
        website = _stringFrom(_asMap(source), const ['websiteUrl', 'customDomain', 'website', 'domain']),
        socialLabels = _socialLabels(_asMap(source)['socialLinks']);

  const SuperadminCompanyInfo({required this.name, required this.website, required this.socialLabels});

  final String name;
  final String website;
  final List<String> socialLabels;

  Map<String, Object?> get asMap => <String, Object?>{
        'name': name,
        'companyName': name,
        'websiteUrl': website,
        'customDomain': website,
        'socialLinks': <String, Object?>{for (final label in socialLabels) label: label},
      };

  static List<String> _socialLabels(Object? source) {
    if (source is! Map) return const <String>[];
    final out = <String>[];
    for (final entry in source.entries) {
      final text = entry.value?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      final label = _titleCaseKey(entry.key.toString());
      if (label.isNotEmpty) out.add(label);
    }
    out.sort();
    return out;
  }

  static String _titleCaseKey(String key) {
    final clean = key.replaceAll('_', ' ').trim();
    if (clean.isEmpty) return '';
    return clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((word) => word.length == 1 ? word.toUpperCase() : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static String _stringFrom(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}

class SuperadminAddressInfo {
  SuperadminAddressInfo.fromObject(Object? source)
      : addressLine = _stringFrom(_asMap(source), const ['addressLine', 'address1', 'address_line']),
        city = _stringFrom(_asMap(source), const ['city', 'cityName', 'cityId']),
        state = _stringFrom(_asMap(source), const ['state', 'stateCode']),
        country = _stringFrom(_asMap(source), const ['country', 'countryCode']),
        pincode = _stringFrom(_asMap(source), const ['pincode', 'postalCode']);

  const SuperadminAddressInfo({required this.addressLine, required this.city, required this.state, required this.country, required this.pincode});

  final String addressLine;
  final String city;
  final String state;
  final String country;
  final String pincode;

  Map<String, Object?> get asMap => <String, Object?>{
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
      };

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static String _stringFrom(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}
