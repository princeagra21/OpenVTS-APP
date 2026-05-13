class UserPolicy {
  UserPolicy(Object? source)
      : policyType = _firstString(_asMap(source), const ['PolicyType', 'policyType', 'type', 'key', 'name', 'slug']),
        policyText = _firstString(_asMap(source), const ['PolicyText', 'policyText', 'text', 'content', 'body']),
        title = _firstString(_asMap(source), const ['title', 'label', 'displayName', 'name']);

  const UserPolicy.typed({required this.policyType, required this.policyText, required this.title});

  final String policyType;
  final String policyText;
  final String title;

  bool get hasContent => policyText.trim().isNotEmpty;

  static List<UserPolicy> fromResponse(Object? data) {
    final out = <UserPolicy>[];
    final root = _unwrap(data);

    if (root is List) {
      for (final item in root) {
        if (item is Map) out.add(UserPolicy(item));
      }
      return out;
    }

    final rootMap = _asMap(root);
    if (rootMap.isEmpty) return out;

    if (_looksLikeSinglePolicy(rootMap)) {
      out.add(UserPolicy(rootMap));
      return out;
    }

    final maybeList = rootMap['policies'];
    if (maybeList is List) {
      for (final item in maybeList) {
        if (item is Map) out.add(UserPolicy(item));
      }
      if (out.isNotEmpty) return out;
    }

    if (_looksLikePolicyDictionary(rootMap)) {
      for (final entry in rootMap.entries) {
        final key = entry.key.trim();
        if (key.isEmpty) continue;
        final value = entry.value;
        if (value is String) {
          out.add(UserPolicy.typed(policyType: key, policyText: value, title: key));
          continue;
        }
        if (value is Map) {
          final valueMap = _asMap(value);
          out.add(
            UserPolicy.typed(
              policyType: _firstString(valueMap, const ['PolicyType', 'policyType', 'type', 'key']).isEmpty
                  ? key
                  : _firstString(valueMap, const ['PolicyType', 'policyType', 'type', 'key']),
              policyText: _firstString(valueMap, const ['PolicyText', 'policyText', 'text', 'content', 'body']),
              title: _firstString(valueMap, const ['title', 'label', 'displayName', 'name']),
            ),
          );
        }
      }
    }
    return out;
  }

  static Object? _unwrap(Object? data) {
    Object? current = data;
    for (var i = 0; i < 6; i++) {
      final map = _asMap(current);
      if (map.isEmpty) return current;
      if (_looksLikeSinglePolicy(map)) return map;
      var moved = false;
      for (final key in const ['data', 'result', 'items', 'policies', 'settings']) {
        final nested = map[key];
        if (nested is List || nested is Map) {
          current = nested;
          moved = true;
          break;
        }
      }
      if (!moved) return map;
    }
    return current;
  }

  static bool _looksLikeSinglePolicy(Map<String, Object?> map) {
    return map.containsKey('PolicyType') ||
        map.containsKey('policyType') ||
        map.containsKey('PolicyText') ||
        map.containsKey('policyText') ||
        map.containsKey('text') ||
        map.containsKey('content');
  }

  static bool _looksLikePolicyDictionary(Map<String, Object?> map) {
    if (map.isEmpty) return false;
    const metadataKeys = {'status', 'action', 'message', 'timestamp', 'code', 'success'};
    final hasMetadata = map.keys.any((k) => metadataKeys.contains(k.trim().toLowerCase()));
    if (hasMetadata) return false;
    return map.values.any((v) => v is String || v is Map);
  }

  static String _firstString(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }
}
