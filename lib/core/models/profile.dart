class Profile {
  final Map<String, dynamic> raw;

  const Profile(this.raw);

  Map<String, dynamic> get data {
    final d = raw['data'];
    if (d is Map) {
      return Map<String, dynamic>.from(d.cast());
    }
    return raw;
  }

  List<String> get keys => data.keys.map((k) => k.toString()).toList()..sort();

  String get id => _stringFromAny(
    data['id'] ??
        data['userId'] ??
        data['user_id'] ??
        data['uuid'] ??
        data['uid'],
  );

  String get email => _stringFromAny(data['email'] ?? data['mail']);

  String get name => _stringFromAny(
    data['name'] ?? data['fullName'] ?? data['full_name'] ?? data['username'],
  );

  String get phone => _stringFromAny(
    data['phone'] ??
        data['mobile'] ??
        data['mobileNumber'] ??
        data['mobile_number'],
  );

  String get role => _stringFromAny(
    data['role'] ?? data['userType'] ?? data['user_type'] ?? data['type'],
  );

  String get username =>
      _stringFromAny(data['username'] ?? data['handle'] ?? data['userName']);

  static String _stringFromAny(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
