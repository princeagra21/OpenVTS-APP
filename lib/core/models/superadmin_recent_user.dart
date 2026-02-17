class SuperadminRecentUser {
  final Map<String, dynamic> raw;

  const SuperadminRecentUser(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ?? raw['userId'] ?? raw['user_id'] ?? raw['uuid'] ?? raw['uid'],
  );

  String get name => _string(
    raw['name'] ??
        raw['fullName'] ??
        raw['full_name'] ??
        raw['username'] ??
        raw['title'],
  );

  String get email => _string(raw['email'] ?? raw['mail']);

  String get status => _string(
    raw['status'] ?? raw['state'] ?? raw['userStatus'] ?? raw['user_status'],
  );

  String get time => _string(
    raw['time'] ??
        raw['createdAt'] ??
        raw['created_at'] ??
        raw['updatedAt'] ??
        raw['updated_at'],
  );

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
