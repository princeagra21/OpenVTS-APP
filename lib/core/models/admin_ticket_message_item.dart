class AdminTicketMessageItem {
  final Map<String, dynamic> raw;

  const AdminTicketMessageItem(this.raw);

  String get id => _string(raw['id'] ?? raw['_id'] ?? raw['messageId']);

  String get senderName => _string(
    raw['senderName'] ??
        raw['sender'] ??
        raw['author'] ??
        raw['createdBy'] ??
        (raw['user'] is Map ? (raw['user'] as Map)['name'] : null),
  );

  String get message =>
      _string(raw['message'] ?? raw['content'] ?? raw['text']);

  String get createdAt => _string(
    raw['createdAt'] ?? raw['created_at'] ?? raw['timestamp'] ?? raw['at'],
  );

  bool get isInternal {
    final direct = raw['isInternal'] ?? raw['internal'] ?? raw['isNote'];
    if (direct is bool) return direct;
    if (direct is num) return direct != 0;

    final type = _string(raw['type']).toLowerCase();
    return type == 'internal' || type == 'note';
  }

  static String _string(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }
}
