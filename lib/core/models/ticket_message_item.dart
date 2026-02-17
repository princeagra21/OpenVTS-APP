class TicketMessageItem {
  final Map<String, dynamic> raw;

  const TicketMessageItem(this.raw);

  String get id => _s(raw['id'] ?? raw['_id'] ?? raw['messageId']);

  String get message => _s(raw['message'] ?? raw['content'] ?? raw['text']);

  String get createdAt => _s(
    raw['createdAt'] ?? raw['created_at'] ?? raw['timestamp'] ?? raw['at'],
  );

  String get senderName => _s(
    raw['senderName'] ??
        raw['sender'] ??
        raw['author'] ??
        (raw['user'] is Map ? (raw['user'] as Map)['name'] : null),
  );

  bool get isInternal {
    final v = raw['isInternal'] ?? raw['internal'] ?? raw['type'];
    if (v is bool) return v;
    final s = _s(v).toLowerCase();
    return s == 'internal' || s == 'note' || s == 'true';
  }

  static String _s(Object? v) => v == null ? '' : v.toString();
}
