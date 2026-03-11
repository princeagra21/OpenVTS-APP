class UserRecentAlertItem {
  final Map<String, dynamic> raw;

  const UserRecentAlertItem(this.raw);

  String get id => _string(
    raw['id'] ?? raw['_id'] ?? raw['alertId'] ?? raw['notificationId'],
  );

  String get title =>
      _nonEmpty([
        raw['title'],
        raw['action'],
        raw['type'],
        raw['category'],
        raw['subject'],
      ]) ??
      'Alert';

  String get message =>
      _nonEmpty([
        raw['message'],
        raw['description'],
        raw['body'],
        raw['summary'],
        raw['content'],
      ]) ??
      title;

  String get createdAt => _string(
    raw['createdAt'] ?? raw['timestamp'] ?? raw['time'] ?? raw['date'],
  );

  bool get isRead => _bool(raw['isRead'] ?? raw['read']);

  String get displayText {
    final t = title.trim();
    final m = message.trim();
    if (m.isEmpty || m == t) return t;
    return '$t: $m';
  }

  static String _string(Object? value) => (value ?? '').toString().trim();

  static bool _bool(Object? value) {
    if (value is bool) return value;
    final raw = _string(value).toLowerCase();
    return raw == 'true' || raw == '1' || raw == 'yes';
  }

  static String? _nonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = _string(value);
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}
