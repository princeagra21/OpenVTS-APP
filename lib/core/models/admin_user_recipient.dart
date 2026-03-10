class AdminUserRecipient {
  final Map<String, dynamic> raw;

  const AdminUserRecipient(this.raw);

  String get id {
    return _str(
      raw['id'] ?? raw['uid'] ?? raw['userId'] ?? raw['_id'] ?? raw['value'],
    );
  }

  String get name {
    return _str(
      raw['name'] ??
          raw['fullName'] ??
          raw['username'] ??
          raw['displayName'] ??
          raw['title'],
    );
  }

  String get email {
    return _str(raw['email'] ?? raw['userEmail'] ?? raw['mail']);
  }

  String get initials {
    final n = name.trim();
    if (n.isEmpty) return '--';
    final parts = n.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  static String _str(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }
}
