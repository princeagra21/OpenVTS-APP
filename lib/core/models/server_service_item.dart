class ServerServiceItem {
  final Map<String, dynamic> raw;

  const ServerServiceItem(this.raw);

  String get name => _s(raw['name'] ?? raw['service'] ?? raw['id']);

  String get status =>
      _s(raw['status'] ?? raw['state'] ?? raw['health']).toLowerCase();

  String get since => _s(
    raw['since'] ?? raw['sinceAt'] ?? raw['startedAt'] ?? raw['updatedAt'],
  );

  String get note => _s(raw['note'] ?? raw['message'] ?? raw['details']);

  bool get isUp {
    final s = status;
    return s == 'running' || s == 'up' || s == 'ok' || s == 'healthy';
  }

  static List<ServerServiceItem> listFromHealth(Object? payload) {
    final root = _m(payload);
    final data = _m(root['data']);
    final source = data.isNotEmpty ? data : root;

    final directList = _toMapList(
      source['services'] ??
          source['checks'] ??
          source['components'] ??
          source['items'],
    );
    if (directList != null) {
      return directList.map(ServerServiceItem.new).toList();
    }

    final servicesMap = _m(source['services']);
    if (servicesMap.isNotEmpty) {
      return servicesMap.entries.map((entry) {
        final m = _m(entry.value);
        return ServerServiceItem({
          ...m,
          if (_s(m['name']).isEmpty) 'name': entry.key,
        });
      }).toList();
    }
    return const [];
  }

  static String _s(Object? v) => v == null ? '' : v.toString();

  static Map<String, dynamic> _m(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v.cast());
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>>? _toMapList(Object? value) {
    if (value is List) {
      return value
          .whereType<Object>()
          .map((e) => e is Map ? _m(e) : const <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();
    }
    return null;
  }
}
