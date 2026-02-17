class RoleItem {
  final Map<String, dynamic> raw;

  const RoleItem(this.raw);

  String get id => _string(raw['id'] ?? raw['roleId'] ?? raw['role_id']);

  String get name => _string(
    raw['name'] ?? raw['roleName'] ?? raw['title'] ?? raw['label'],
  );

  String get description =>
      _string(raw['description'] ?? raw['desc'] ?? raw['summary']);

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}

