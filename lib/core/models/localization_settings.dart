class LocalizationSettings {
  final Map<String, dynamic> raw;

  const LocalizationSettings(this.raw);

  String get languageCode =>
      _firstString(const ['language', 'lang', 'locale', 'defaultLanguage']);

  String get textDirection {
    final explicit = _firstString(const [
      'direction',
      'textDirection',
      'layoutDirection',
    ]);
    if (explicit.isNotEmpty) {
      final up = explicit.toUpperCase();
      return up == 'RTL' ? 'RTL' : 'LTR';
    }

    final rtlEnabled = _firstBool(const ['rtlEnabled', 'isRtl']);
    if (rtlEnabled != null) return rtlEnabled ? 'RTL' : 'LTR';
    return '';
  }

  String get dateFormat =>
      _firstString(const ['dateFormat', 'date_format', 'dateformat']);

  String get timeFormat {
    final explicit = _firstString(const ['timeFormat', 'time_format']);
    if (explicit.isNotEmpty) return explicit;

    final use24Hour = _firstBool(const ['use24Hour', 'use_24_hour']);
    if (use24Hour != null) return use24Hour ? '24-hour' : '12-hour';
    return '';
  }

  bool? get use24Hour {
    final use24 = _firstBool(const ['use24Hour', 'use_24_hour']);
    if (use24 != null) return use24;

    final tf = timeFormat.trim().toLowerCase();
    if (tf == '24-hour' || tf == '24h' || tf == '24') return true;
    if (tf == '12-hour' || tf == '12h' || tf == '12') return false;
    return null;
  }

  String get timezone => _firstString(const [
    'timezone',
    'tz',
    'timezoneOffset',
    'timeZone',
    'offset',
  ]);

  String get units => _firstString(const ['units', 'unitSystem', 'kmMiles']);

  double? get mapLat =>
      _firstDouble(const ['mapLat', 'defaultLat', 'latitude', 'lat']);

  double? get mapLng =>
      _firstDouble(const ['mapLng', 'defaultLon', 'longitude', 'lng', 'lon']);

  int? get mapZoom => _firstInt(const ['mapZoom', 'zoom']);

  String _firstString(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final s = value.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  bool? _firstBool(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final s = value.toString().trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return null;
  }

  double? _firstDouble(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  int? _firstInt(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }
}
