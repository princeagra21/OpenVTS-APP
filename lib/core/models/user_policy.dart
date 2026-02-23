class UserPolicy {
  final Map<String, dynamic> raw;

  const UserPolicy(this.raw);

  String get policyType => _firstString(const [
    'PolicyType',
    'policyType',
    'type',
    'key',
    'name',
    'slug',
  ]);

  String get policyText => _firstString(const [
    'PolicyText',
    'policyText',
    'text',
    'content',
    'body',
  ]);

  String get title =>
      _firstString(const ['title', 'label', 'displayName', 'name']);

  bool get hasContent => policyText.trim().isNotEmpty;

  static List<UserPolicy> fromResponse(Object? data) {
    final out = <UserPolicy>[];
    final dynamic root = _unwrap(data);

    if (root is List) {
      for (final item in root) {
        if (item is Map<String, dynamic>) {
          out.add(UserPolicy(item));
        } else if (item is Map) {
          out.add(UserPolicy(Map<String, dynamic>.from(item.cast())));
        }
      }
      return out;
    }

    if (root is Map<String, dynamic>) {
      if (_looksLikeSinglePolicy(root)) {
        out.add(UserPolicy(root));
        return out;
      }

      final maybeList = root['policies'];
      if (maybeList is List) {
        for (final item in maybeList) {
          if (item is Map<String, dynamic>) {
            out.add(UserPolicy(item));
          } else if (item is Map) {
            out.add(UserPolicy(Map<String, dynamic>.from(item.cast())));
          }
        }
        if (out.isNotEmpty) return out;
      }

      // Handle map forms like { "PRIVACY_POLICY": "text..." }.
      if (_looksLikePolicyDictionary(root)) {
        for (final entry in root.entries) {
          final key = entry.key.trim();
          if (key.isEmpty) continue;
          final value = entry.value;
          if (value is String) {
            out.add(
              UserPolicy(<String, dynamic>{
                'PolicyType': key,
                'PolicyText': value,
              }),
            );
            continue;
          }
          if (value is Map<String, dynamic>) {
            final map = <String, dynamic>{...value};
            map.putIfAbsent('PolicyType', () => key);
            out.add(UserPolicy(map));
            continue;
          }
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            map.putIfAbsent('PolicyType', () => key);
            out.add(UserPolicy(map));
          }
        }
      }
      return out;
    }

    if (root is Map) {
      return fromResponse(Map<String, dynamic>.from(root.cast()));
    }

    return out;
  }

  static dynamic _unwrap(Object? data) {
    dynamic current = data;
    for (int i = 0; i < 6; i++) {
      if (current is Map<String, dynamic>) {
        if (_looksLikeSinglePolicy(current)) return current;

        bool moved = false;
        for (final key in const [
          'data',
          'result',
          'items',
          'policies',
          'settings',
        ]) {
          final nested = current[key];
          if (nested is List ||
              nested is Map<String, dynamic> ||
              nested is Map) {
            current = nested;
            moved = true;
            break;
          }
        }
        if (!moved) return current;
        continue;
      }

      if (current is Map) {
        current = Map<String, dynamic>.from(current.cast());
        continue;
      }

      return current;
    }
    return current;
  }

  static bool _looksLikeSinglePolicy(Map<String, dynamic> map) {
    return map.containsKey('PolicyType') ||
        map.containsKey('policyType') ||
        map.containsKey('PolicyText') ||
        map.containsKey('policyText') ||
        map.containsKey('text') ||
        map.containsKey('content');
  }

  static bool _looksLikePolicyDictionary(Map<String, dynamic> map) {
    if (map.isEmpty) return false;

    const metadataKeys = {
      'status',
      'action',
      'message',
      'timestamp',
      'code',
      'success',
    };

    final hasMetadata = map.keys.any(
      (k) => metadataKeys.contains(k.trim().toLowerCase()),
    );
    if (hasMetadata) return false;

    return map.values.any(
      (v) => v is String || v is Map<String, dynamic> || v is Map,
    );
  }

  String _firstString(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
