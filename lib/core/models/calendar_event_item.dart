class CalendarEventItem {
  final Map<String, dynamic> raw;

  const CalendarEventItem(this.raw);

  String get id => _s(raw['id'] ?? raw['_id'] ?? raw['eventId']);

  String get type =>
      _s(raw['type'] ?? raw['category'] ?? raw['eventType'] ?? raw['kind']);

  String get title =>
      _s(raw['title'] ?? raw['summary'] ?? raw['name'] ?? raw['event']);

  String get label => title;

  String get description =>
      _s(raw['description'] ?? raw['message'] ?? raw['details'] ?? raw['note']);

  DateTime? get date {
    final candidates = [
      raw['date'],
      raw['eventDate'],
      raw['start'],
      raw['startDate'],
      raw['startAt'],
      raw['createdAt'],
      raw['timestamp'],
    ];
    for (final c in candidates) {
      final d = _dt(c);
      if (d != null) return d;
    }
    return null;
  }

  String get time => _s(raw['time'] ?? raw['eventTime'] ?? raw['startTime']);

  DateTime? get createdAt {
    final candidates = [
      raw['createdAt'],
      raw['updatedAt'],
      raw['timestamp'],
      raw['time'],
    ];
    for (final c in candidates) {
      final d = _dt(c);
      if (d != null) return d;
    }
    return null;
  }

  String get adminId =>
      _s(raw['adminId'] ?? raw['admin_id'] ?? raw['administratorId']);

  String get userId => _s(raw['userId'] ?? raw['user_id']);

  String get vehicleId =>
      _s(raw['vehicleId'] ?? raw['vehicle_id'] ?? raw['deviceId']);

  Map<String, dynamic> get metadata {
    final m = _m(raw['metadata']);
    if (m.isNotEmpty) return m;
    return <String, dynamic>{
      if (raw['adminId'] != null) 'adminId': raw['adminId'],
      if (raw['userId'] != null) 'userId': raw['userId'],
      if (raw['vehicleId'] != null) 'vehicleId': raw['vehicleId'],
    };
  }

  static String _s(Object? v) => v == null ? '' : v.toString();

  static Map<String, dynamic> _m(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v.cast());
    return const <String, dynamic>{};
  }

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
