class VehicleUserItem {
  final Map<String, dynamic> raw;

  const VehicleUserItem(this.raw);

  String get id => _s(raw['id'] ?? raw['userId'] ?? raw['user_id']);

  String get name => _s(raw['name'] ?? raw['fullName'] ?? raw['full_name']);

  String get username => _s(raw['username'] ?? raw['handle']);

  String get email => _s(raw['email'] ?? raw['mail']);

  String get phone => _s(
    raw['phone'] ??
        raw['mobileNumber'] ??
        raw['mobile'] ??
        raw['phoneNumber'],
  );

  String get lastSeen => _s(
    raw['lastSeen'] ??
        raw['lastSeenAt'] ??
        raw['last_seen_at'] ??
        raw['recentLogin'] ??
        raw['lastLogin'],
  );

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}

