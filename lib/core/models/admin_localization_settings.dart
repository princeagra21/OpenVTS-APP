class AdminLocalizationSettings {
  final Map<String, dynamic> raw;

  const AdminLocalizationSettings(this.raw);

  String get languageCode => _firstString(const [
    'languageCode',
    'language_code',
    'language',
    'lang',
    'locale',
    'defaultLanguage',
  ]);

  String get direction {
    final explicit = _firstString(const [
      'layoutDirection',
      'direction',
      'textDirection',
      'layout_direction',
    ]);
    if (explicit.isNotEmpty) {
      return explicit.trim().toUpperCase() == 'RTL' ? 'RTL' : 'LTR';
    }

    final rtlEnabled = _firstBool(const ['rtlEnabled', 'isRtl']);
    if (rtlEnabled != null) return rtlEnabled ? 'RTL' : 'LTR';

    return '';
  }

  String get timezone => _firstString(const [
    'timezoneOffset',
    'timezone',
    'timeZone',
    'tz',
    'offset',
  ]);

  String get dateFormat =>
      _firstString(const ['dateFormat', 'date_format', 'dateformat']);

  bool? get use24Hour {
    final direct = _firstBool(const ['use24Hour', 'use_24_hour']);
    if (direct != null) return direct;

    final tf = _firstString(const [
      'timeFormat',
      'time_format',
    ]).trim().toLowerCase();
    if (tf == '24-hour' || tf == '24h' || tf == '24') return true;
    if (tf == '12-hour' || tf == '12h' || tf == '12') return false;
    return null;
  }

  String get timeFormat {
    final explicit = _firstString(const ['timeFormat', 'time_format']);
    if (explicit.isNotEmpty) return explicit;

    final use24 = use24Hour;
    if (use24 == true) return '24-hour';
    if (use24 == false) return '12-hour';
    return '';
  }

  String get units => _firstString(const [
    'units',
    'unitSystem',
    'distanceUnit',
    'distance_unit',
    'kmMiles',
  ]);

  double? get mapLat =>
      _firstDouble(const ['defaultLat', 'mapLat', 'latitude', 'lat']);

  double? get mapLng =>
      _firstDouble(const ['defaultLon', 'mapLng', 'longitude', 'lng', 'lon']);

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
