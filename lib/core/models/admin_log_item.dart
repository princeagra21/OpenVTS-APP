class AdminLogItem {
  final Map<String, dynamic> raw;

  const AdminLogItem(this.raw);

  String get id => _string(
    raw['id'] ?? raw['_id'] ?? raw['logId'] ?? raw['eventId'] ?? raw['uid'],
  );

  String get time => _string(
    raw['time'] ??
        raw['createdAt'] ??
        raw['created_at'] ??
        raw['timestamp'] ??
        raw['occurredAt'],
  );

  String get type => _string(
    raw['type'] ?? raw['entityType'] ?? raw['source'] ?? raw['packetType'],
  );

  String get entity => _string(
    raw['entity'] ??
        raw['entityName'] ??
        raw['vehicleName'] ??
        raw['userName'] ??
        raw['driverName'] ??
        raw['name'],
  );

  String get message => _string(
    raw['message'] ?? raw['summary'] ?? raw['description'] ?? raw['action'],
  );

  String get channel => _string(
    raw['channel'] ?? raw['medium'] ?? raw['transport'] ?? raw['source'],
  );

  String get severity =>
      _string(raw['severity'] ?? raw['level'] ?? raw['status']);

  String get normalizedSeverity {
    final value = severity.toLowerCase();
    if (value.contains('warn')) return 'warning';
    if (value.contains('error') ||
        value.contains('critical') ||
        value.contains('fail')) {
      return 'error';
    }
    if (value.contains('info') ||
        value.contains('ok') ||
        value.contains('success')) {
      return 'info';
    }
    return value;
  }

  static String _string(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }
}
