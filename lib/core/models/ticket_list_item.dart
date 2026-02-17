class TicketListItem {
  final Map<String, dynamic> raw;

  const TicketListItem(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['ticketId'] ??
        raw['ticket_id'] ??
        raw['code'] ??
        raw['reference'] ??
        raw['ref'],
  );

  String get subject =>
      _string(raw['subject'] ?? raw['title'] ?? raw['name'] ?? raw['summary']);

  String get ticketNumber => _string(
    raw['ticketNumber'] ?? raw['ticketNo'] ?? raw['code'] ?? raw['reference'],
  );

  String get ownerName => _string(
    raw['ownerName'] ??
        raw['owner'] ??
        raw['requesterName'] ??
        raw['assignedToName'] ??
        userName,
  );

  String get snippet => _string(
    raw['snippet'] ??
        raw['preview'] ??
        raw['description'] ??
        raw['message'] ??
        raw['subject'],
  );

  String get status => _string(raw['status'] ?? raw['state']);

  String get priority => _string(raw['priority'] ?? raw['severity']);

  String get createdAt =>
      _string(raw['createdAt'] ?? raw['created_at'] ?? raw['created']);

  String get userName => _string(
    raw['userName'] ??
        raw['user'] ??
        raw['customerName'] ??
        raw['customer'] ??
        (raw['user'] is Map ? (raw['user'] as Map)['name'] : null) ??
        (raw['customer'] is Map ? (raw['customer'] as Map)['name'] : null),
  );

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
