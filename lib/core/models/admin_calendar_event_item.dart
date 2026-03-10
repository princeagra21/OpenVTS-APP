class AdminCalendarEventItem {
  final Map<String, dynamic> raw;

  const AdminCalendarEventItem(this.raw);

  String get id => _string(
    raw['id'] ?? raw['_id'] ?? raw['eventId'] ?? raw['uid'] ?? raw['code'],
  );

  String get title => _string(
    raw['title'] ??
        raw['name'] ??
        raw['label'] ??
        raw['summary'] ??
        raw['type'],
  );

  String get description => _string(
    raw['description'] ?? raw['message'] ?? raw['details'] ?? raw['note'],
  );

  String get type =>
      _string(raw['type'] ?? raw['category'] ?? raw['eventType']);

  String get date => _string(
    raw['date'] ??
        raw['eventDate'] ??
        raw['day'] ??
        raw['startDate'] ??
        raw['start'] ??
        raw['createdAt'],
  );

  String get time => _string(
    raw['time'] ??
        raw['eventTime'] ??
        raw['startTime'] ??
        raw['hour'] ??
        raw['createdAt'],
  );

  String get adminId => _string(raw['adminId'] ?? raw['createdByAdminId']);
  String get userId => _string(raw['userId'] ?? raw['uid']);
  String get vehicleId =>
      _string(raw['vehicleId'] ?? raw['vehicle'] ?? raw['vehicle_id']);

  DateTime? get dateTime {
    final dt = _tryParse(date);
    if (dt != null) return dt;
    return _tryParse(time);
  }

  String get normalizedType {
    final t = type.toLowerCase();
    final titleLower = title.toLowerCase();
    final hint = '$t $titleLower';

    if (hint.contains('admin')) return 'admin';
    if (hint.contains('user')) return 'user';
    if (hint.contains('expiry') || hint.contains('expire')) {
      return 'vehicle_expiry';
    }
    if (hint.contains('vehicle') && hint.contains('add')) {
      return 'vehicle_added';
    }
    if (hint.contains('vehicle')) return 'vehicle';
    return t;
  }

  DateTime? _tryParse(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String _string(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }
}
