class CommandOption {
  final Map<String, dynamic> raw;

  const CommandOption(this.raw);

  String get id => _s(raw['id'] ?? raw['commandTypeId'] ?? raw['code']);

  String get name => _s(raw['name'] ?? raw['title'] ?? raw['command']);

  String get code => _s(raw['code'] ?? raw['command'] ?? raw['name']);

  bool get requiresPayload {
    final v =
        raw['requiresPayload'] ?? raw['requires_data'] ?? raw['hasPayload'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      return t == 'true' || t == '1' || t == 'yes';
    }
    return true;
  }

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
