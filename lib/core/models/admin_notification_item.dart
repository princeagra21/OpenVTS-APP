class AdminNotificationItem {
  final Map<String, dynamic> raw;

  const AdminNotificationItem(this.raw);

  String get id => _string(
    raw['id'] ??
        raw['notificationId'] ??
        raw['notification_id'] ??
        raw['uid'] ??
        raw['_id'] ??
        raw['code'],
  );

  String get title =>
      _string(raw['title'] ?? raw['subject'] ?? raw['name'] ?? raw['heading']);

  String get body => _string(
    raw['message'] ?? raw['body'] ?? raw['description'] ?? raw['content'],
  );

  String get createdAt => _string(
    raw['createdAt'] ??
        raw['created_at'] ??
        raw['timestamp'] ??
        raw['time'] ??
        raw['date'],
  );

  String get type => _string(
    raw['type'] ?? raw['category'] ?? raw['kind'] ?? raw['eventType'],
  );

  bool get isRead {
    final direct = _boolOrNull(
      raw['isRead'] ?? raw['read'] ?? raw['is_read'] ?? raw['seen'],
    );
    if (direct != null) return direct;

    final status = _string(raw['status'] ?? raw['state']).toLowerCase();
    if (status == 'read' || status == 'seen' || status == 'closed') {
      return true;
    }
    if (status == 'unread' || status == 'new' || status == 'open') {
      return false;
    }
    return false;
  }

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  static bool? _boolOrNull(Object? v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return null;
  }
}
