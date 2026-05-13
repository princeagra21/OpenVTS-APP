class ApiEnvelope {
  static const List<String> _defaultMapKeys = <String>[
    'data',
    'result',
    'item',
    'payload',
    'response',
  ];

  static const List<String> _defaultListKeys = <String>[
    'data',
    'items',
    'result',
    'results',
    'rows',
    'list',
  ];

  static const List<String> _defaultMessageKeys = <String>[
    'message',
    'error',
    'msg',
    'detail',
    'reason',
  ];

  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static Map<String, dynamic> nestedMap(
    Object? value, {
    List<String> mapKeys = _defaultMapKeys,
    int maxDepth = 4,
  }) {
    var current = asMap(value);
    if (current.isEmpty) return const <String, dynamic>{};

    var best = current;
    for (var depth = 0; depth < maxDepth; depth++) {
      var advanced = false;
      for (final key in mapKeys) {
        final candidate = asMap(current[key]);
        if (candidate.isNotEmpty) {
          best = candidate;
          current = candidate;
          advanced = true;
          break;
        }
      }
      if (!advanced) break;
    }

    return best;
  }

  static Map<String, dynamic> payload(
    Object? value, {
    List<String> mapKeys = _defaultMapKeys,
  }) {
    final root = asMap(value);
    if (root.isEmpty) return const <String, dynamic>{};

    final nested = nestedMap(root, mapKeys: mapKeys);
    if (nested.isNotEmpty) return nested;

    for (final key in mapKeys) {
      final candidate = asMap(root[key]);
      if (candidate.isNotEmpty) return candidate;
    }

    return root;
  }

  static List<dynamic>? list(
    Object? value, {
    List<String> listKeys = _defaultListKeys,
    int maxDepth = 6,
  }) {
    List<dynamic>? walk(Object? node, int depth) {
      if (depth > maxDepth) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = asMap(node);
      for (final key in listKeys) {
        final candidate = map[key];
        if (candidate is List) return candidate;
      }

      for (final candidate in map.values) {
        if (candidate is Map || candidate is List) {
          final found = walk(candidate, depth + 1);
          if (found != null) return found;
        }
      }

      return null;
    }

    return walk(value, 0);
  }

  static List<Map<String, dynamic>> mapList(
    Object? value, {
    List<String> listKeys = _defaultListKeys,
    int maxDepth = 6,
  }) {
    final raw = list(value, listKeys: listKeys, maxDepth: maxDepth);
    if (raw == null) return const <Map<String, dynamic>>[];

    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      final map = asMap(item);
      if (map.isNotEmpty) out.add(map);
    }
    return out;
  }

  static String? message(
    Object? value, {
    List<String> messageKeys = _defaultMessageKeys,
  }) {
    String? fromMap(Map<String, dynamic> map) {
      for (final key in messageKeys) {
        final candidate = map[key];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
      return null;
    }

    final root = asMap(value);
    if (root.isNotEmpty) {
      final direct = fromMap(root);
      if (direct != null) return direct;

      final nested = nestedMap(root);
      final nestedMessage = fromMap(nested);
      if (nestedMessage != null) return nestedMessage;

      final action = boolValue(root['action']);
      if (action == false) {
        return fromMap(root) ?? fromMap(nested);
      }
    }

    return null;
  }

  static String errorMessage(
    Object? value, {
    String fallback = 'Unknown error',
  }) {
    final msg = message(value);
    if (msg != null && msg.trim().isNotEmpty) return msg.trim();
    return fallback;
  }

  static bool isEmptyResponse(Object? value) {
    if (value == null) return true;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  static bool? boolValue(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (const <String>{'true', '1', 'yes', 'y'}.contains(text)) return true;
    if (const <String>{'false', '0', 'no', 'n'}.contains(text)) return false;
    return null;
  }

  static String text(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static String firstNonEmpty(
    Iterable<Object?> values, {
    String fallback = '',
  }) {
    for (final value in values) {
      final candidate = text(value).trim();
      if (candidate.isNotEmpty) return candidate;
    }
    return fallback;
  }
}
