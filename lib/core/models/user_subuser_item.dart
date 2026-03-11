class UserSubUserItem {
  final Map<String, dynamic> raw;

  const UserSubUserItem(this.raw);

  String get id => _string(raw['id'] ?? raw['_id'] ?? raw['userId']);

  String get name => _string(
    raw['name'] ?? raw['fullName'] ?? raw['full_name'] ?? raw['username'],
  );

  String get username => _string(raw['username'] ?? raw['handle']);

  String get email => _string(raw['email'] ?? raw['mail']);

  String get mobilePrefix => _string(raw['mobilePrefix'] ?? raw['prefix']);

  String get mobileNumber => _string(
    raw['mobileNumber'] ?? raw['mobile'] ?? raw['phone'] ?? raw['phoneNumber'],
  );

  String get fullPhone {
    if (mobilePrefix.isEmpty) return mobileNumber;
    if (mobileNumber.isEmpty) return mobilePrefix;
    return '$mobilePrefix $mobileNumber';
  }

  bool get isActive {
    final value = raw['isActive'] ?? raw['active'] ?? raw['status'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'active' || text == 'true' || text == '1') return true;
    if (text == 'disabled' ||
        text == 'inactive' ||
        text == 'false' ||
        text == '0') {
      return false;
    }
    return true;
  }

  String get statusLabel => isActive ? 'Active' : 'Disabled';

  String get permissionsLabel {
    final direct = _string(
      raw['permissionsLabel'] ?? raw['permissions'] ?? raw['scopesLabel'],
    );
    if (direct.isNotEmpty) return direct;

    final permissions = raw['permissions'];
    if (permissions is List) {
      return '${permissions.length} scopes';
    }

    final scopes = raw['scopes'];
    if (scopes is List) {
      return '${scopes.length} scopes';
    }

    return '—';
  }

  static String _string(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }
}
