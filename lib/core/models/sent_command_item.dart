class SentCommandItem {
  final Map<String, dynamic> raw;

  const SentCommandItem(this.raw);

  String get id => _s(raw['id'] ?? raw['commandId'] ?? raw['requestId']);

  String get name => _s(raw['name'] ?? raw['command'] ?? raw['type']);

  String get status => _s(raw['status'] ?? raw['state'] ?? raw['result']);

  String get createdAt => _s(
    raw['createdAt'] ?? raw['created_at'] ?? raw['time'] ?? raw['timestamp'],
  );

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
