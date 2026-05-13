class VehicleUserItem {
  VehicleUserItem(Object? source)
      : id = source is VehicleUserItem ? source.id : _readString(source, const ['id', 'userId', 'user_id']),
        name = source is VehicleUserItem ? source.name : _readString(source, const ['name', 'fullName', 'full_name']),
        username = source is VehicleUserItem ? source.username : _readString(source, const ['username', 'handle']),
        email = source is VehicleUserItem ? source.email : _readString(source, const ['email', 'mail']),
        phone = source is VehicleUserItem ? source.phone : _readString(source, const ['phone', 'mobileNumber', 'mobile', 'phoneNumber']),
        role = source is VehicleUserItem ? source.role : _readString(source, const ['role', 'loginType', 'type']),
        lastSeen = source is VehicleUserItem ? source.lastSeen : _readString(source, const ['lastSeen', 'lastSeenAt', 'last_seen_at', 'recentLogin', 'lastLogin']);

  const VehicleUserItem.typed({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.lastSeen,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String role;
  final String lastSeen;

  Map<String, Object?> get raw => <String, Object?>{
        'id': id,
        'userId': id,
        'name': name,
        'fullName': name,
        'username': username,
        'email': email,
        'phone': phone,
        'role': role,
        'loginType': role,
        'lastSeen': lastSeen,
      };

  Object? valueFor(String key) {
    switch (key) {
      case 'id':
      case 'userId':
      case 'user_id':
        return id;
      case 'name':
      case 'fullName':
      case 'full_name':
        return name;
      case 'username':
      case 'handle':
        return username;
      case 'email':
      case 'mail':
        return email;
      case 'phone':
      case 'mobileNumber':
      case 'mobile':
      case 'phoneNumber':
        return phone;
      case 'role':
      case 'loginType':
      case 'type':
        return role;
      case 'lastSeen':
      case 'lastSeenAt':
      case 'last_seen_at':
      case 'recentLogin':
      case 'lastLogin':
        return lastSeen;
    }
    return null;
  }

  static String _readString(Object? source, List<String> keys) {
    final map = _objectMap(source);
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static Map<String, Object?> _objectMap(Object? source) {
    if (source is VehicleUserItem) {
      return <String, Object?>{
        'id': source.id,
        'name': source.name,
        'username': source.username,
        'email': source.email,
        'phone': source.phone,
        'role': source.role,
        'lastSeen': source.lastSeen,
      };
    }
    if (source is Map) {
      return <String, Object?>{for (final e in source.entries) e.key.toString(): e.value};
    }
    return const <String, Object?>{};
  }
}
