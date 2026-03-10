class AdminTicketListItem {
  final Map<String, dynamic> raw;

  const AdminTicketListItem(this.raw);

  String get id => _string(
    raw['id'] ??
        raw['ticketId'] ??
        raw['ticket_id'] ??
        raw['_id'] ??
        raw['code'] ??
        raw['reference'],
  );

  String get subject =>
      _string(raw['subject'] ?? raw['title'] ?? raw['name'] ?? raw['summary']);

  String get ownerName => _string(
    raw['ownerName'] ??
        raw['owner'] ??
        raw['requesterName'] ??
        raw['userName'] ??
        (raw['user'] is Map ? (raw['user'] as Map)['name'] : null) ??
        (raw['owner'] is Map ? (raw['owner'] as Map)['name'] : null),
  );

  String get status =>
      _string(raw['status'] ?? raw['state'] ?? raw['ticketStatus']);

  String get description => _string(
    raw['description'] ?? raw['message'] ?? raw['snippet'] ?? raw['preview'],
  );

  String get createdAt => _string(
    raw['createdAt'] ?? raw['created_at'] ?? raw['created'] ?? raw['timestamp'],
  );

  String get updatedAt => _string(
    raw['updatedAt'] ??
        raw['updated_at'] ??
        raw['updated'] ??
        raw['lastUpdated'],
  );

  String get ticketNumber => _string(
    raw['ticketNumber'] ?? raw['ticketNo'] ?? raw['code'] ?? raw['reference'],
  );

  String get statusLabel {
    final normalized = normalizeStatus(status);
    switch (normalized) {
      case 'open':
        return 'Open';
      case 'in_process':
      case 'in_progress':
        return 'In Process';
      case 'resolved':
      case 'answered':
        return 'Answered';
      case 'hold':
      case 'on_hold':
        return 'Hold';
      case 'closed':
        return 'Closed';
      default:
        final fallback = status.trim();
        return fallback.isEmpty ? '—' : fallback;
    }
  }

  static String normalizeStatus(String? rawStatus) {
    final value = (rawStatus ?? '').trim().toLowerCase();
    if (value.isEmpty) return '';
    if (value == 'open') return 'open';
    if (value == 'in process' ||
        value == 'in_process' ||
        value == 'inprogress') {
      return 'in_process';
    }
    if (value == 'in_progress' || value == 'processing') return 'in_progress';
    if (value == 'resolved' || value == 'answer' || value == 'answered') {
      return 'resolved';
    }
    if (value == 'hold' || value == 'on hold' || value == 'on_hold') {
      return 'hold';
    }
    if (value == 'closed' || value == 'done') return 'closed';
    return value.replaceAll(' ', '_');
  }

  static String _string(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }
}
