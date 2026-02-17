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
      return out;
    }

    if (root is Map) {
      return fromResponse(Map<String, dynamic>.from(root.cast()));
    }

    return out;
  }

  static dynamic _unwrap(Object? data) {
    if (data is Map<String, dynamic>) {
      for (final key in const [
        'data',
        'result',
        'items',
        'policies',
        'settings',
      ]) {
        final nested = data[key];
        if (nested is List || nested is Map<String, dynamic> || nested is Map) {
          return nested;
        }
      }
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return data;
  }

  static bool _looksLikeSinglePolicy(Map<String, dynamic> map) {
    return map.containsKey('PolicyType') ||
        map.containsKey('policyType') ||
        map.containsKey('PolicyText') ||
        map.containsKey('policyText') ||
        map.containsKey('text') ||
        map.containsKey('content');
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
