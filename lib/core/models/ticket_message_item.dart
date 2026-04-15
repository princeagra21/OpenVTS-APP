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

  String get attachmentName => _s(
    raw['filename'] ??
        raw['fileName'] ??
        raw['attachmentName'] ??
        _firstAttachmentField('originalName') ??
        _firstAttachmentField('storedName') ??
        (raw['file'] is Map ? (raw['file'] as Map)['name'] : null) ??
        (raw['attachment'] is Map
            ? (raw['attachment'] as Map)['name']
            : null),
  );

  String get attachmentUrl => _s(
    raw['fileUrl'] ??
        raw['url'] ??
        raw['attachmentUrl'] ??
        _firstAttachmentField('filePath') ??
        (raw['file'] is Map ? (raw['file'] as Map)['url'] : null) ??
        (raw['attachment'] is Map
            ? (raw['attachment'] as Map)['url']
            : null),
  );

  Object? _firstAttachmentField(String key) {
    final list = raw['attachments'];
    if (list is List && list.isNotEmpty) {
      final first = list.first;
      if (first is Map) {
        return first[key];
      }
    }
    return null;
  }

  String get senderId => _s(
    raw['senderId'] ??
        raw['userId'] ??
        raw['uid'] ??
        raw['fromUserId'] ??
        raw['adminUserId'] ??
        raw['ownerId'],
  );

  bool get isInternal {
    final v = raw['isInternal'] ?? raw['internal'] ?? raw['type'];
    if (v is bool) return v;
    final s = _s(v).toLowerCase();
    return s == 'internal' || s == 'note' || s == 'true';
  }

  static String _s(Object? v) => v == null ? '' : v.toString();
}
