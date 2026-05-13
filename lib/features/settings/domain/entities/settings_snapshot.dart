class SettingsSnapshot {
  const SettingsSnapshot({required this.values});

  final Map<String, Object?> values;

  String? stringValue(String key) => values[key]?.toString();
  bool boolValue(String key, {bool fallback = false}) {
    final value = values[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }
}
