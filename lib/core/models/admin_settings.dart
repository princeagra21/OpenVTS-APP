class AdminSettings {
  final Map<String, dynamic> raw;

  AdminSettings(this.raw);

  String get language =>
      _firstString(const ['language', 'lang', 'locale']) ?? '';

  String get dateFormat =>
      _firstString(const ['dateFormat', 'date_format', 'dateformat']) ?? '';

  bool? get use24Hour {
    final v = raw['use24Hour'] ?? raw['use_24_hour'] ?? raw['use24hour'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return null;
  }

  String get themeRaw =>
      _firstString(const ['theme', 'themeMode', 'theme_mode']) ?? '';

  String get timezoneOffset => _firstString(
        const ['timezoneOffset', 'timezone', 'timeZone', 'offset'],
      ) ??
      '';

  String get units => _firstString(const ['units', 'unit']) ?? '';

  String? _firstString(List<String> keys) {
    for (final k in keys) {
      final v = raw[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }
}

