class AppPreferences {
  final Map<String, dynamic> raw;

  const AppPreferences(this.raw);

  bool get demoLoginEnabled =>
      _firstBool(const ['allowDemoLogin', 'demoLoginEnabled', 'isDemoLogin']) ??
      false;

  int get reverseGeocodingDigits {
    final explicit = _firstInt(const [
      'reverseGeocodingDigits',
      'geocodingDigits',
      'geoDigits',
    ]);
    if (explicit != null) return explicit >= 3 ? 3 : 2;

    final precision = _firstString(const [
      'geocodingPrecision',
      'reverseGeocodingPrecision',
    ]).toUpperCase();

    if (precision.contains('THREE') || precision.contains('3')) return 3;
    return 2;
  }

  String get backupRetention {
    final days = backupDays;
    if (days <= 30) return '1 Month';
    if (days <= 90) return '3 Months';
    if (days <= 180) return '6 Months';
    return '12 Months';
  }

  int get backupDays {
    final days = _firstInt(const ['backupDays', 'retentionDays']);
    if (days == null) return 90;
    return days <= 0 ? 90 : days;
  }

  bool get allowSignup =>
      _firstBool(const ['allowSignup', 'signupAllowed', 'isSignupAllowed']) ??
      true;

  int get freeSignupCredits {
    final credits = _firstInt(const ['signupCredits', 'freeSignupCredits']);
    if (credits == null) return 100;
    return credits < 0 ? 0 : credits;
  }

  Map<String, dynamic> toPatchPayload({
    required bool demoLoginEnabled,
    required int reverseGeocodingDigits,
    required String backupRetention,
    required bool allowSignup,
    required int freeSignupCredits,
  }) {
    return <String, dynamic>{
      // Postman-confirmed keys for /superadmin/softwareconfig PATCH.
      'allowDemoLogin': demoLoginEnabled,
      'geocodingPrecision': reverseGeocodingDigits >= 3
          ? 'THREE_DIGIT'
          : 'TWO_DIGIT',
      'backupDays': _backupDaysFromRetention(backupRetention),
      'allowSignup': allowSignup,
      'signupCredits': freeSignupCredits,
    };
  }

  int _backupDaysFromRetention(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.startsWith('1')) return 30;
    if (normalized.startsWith('3')) return 90;
    if (normalized.startsWith('6')) return 180;
    if (normalized.startsWith('12')) return 365;
    return 90;
  }

  String _firstString(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final s = value.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
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
}
