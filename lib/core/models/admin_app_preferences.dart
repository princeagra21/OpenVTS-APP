class AdminAppPreferences {
  final Map<String, dynamic> raw;

  const AdminAppPreferences(this.raw);

  bool? get allowDemoLogin =>
      _firstBool(const ['allowDemoLogin', 'demoLoginEnabled', 'isDemoLogin']);

  int? get geocodingPrecision {
    final explicitInt = _firstInt(const [
      'reverseGeocodingDigits',
      'geocodingDigits',
      'geoDigits',
    ]);
    if (explicitInt != null) {
      return explicitInt >= 3 ? 3 : 2;
    }

    final precision = _firstString(const [
      'geocodingPrecision',
      'reverseGeocodingPrecision',
    ]).toUpperCase();
    if (precision.isEmpty) return null;
    if (precision.contains('THREE') || precision.contains('3')) return 3;
    if (precision.contains('TWO') || precision.contains('2')) return 2;
    return null;
  }

  int? get backupDays {
    final days = _firstInt(const [
      'backupDays',
      'backupRetentionDays',
      'retentionDays',
    ]);
    if (days == null) return null;
    if (days < 0) return 0;
    return days;
  }

  String get backupRetentionLabel {
    final days = backupDays;
    if (days == null) return '';
    return retentionLabelFromDays(days);
  }

  bool? get allowSignup =>
      _firstBool(const ['allowSignup', 'signupAllowed', 'isSignupAllowed']);

  int? get signupCredits {
    final credits = _firstInt(const ['signupCredits', 'freeSignupCredits']);
    if (credits == null) return null;
    return credits < 0 ? 0 : credits;
  }

  bool get hasAnyValue {
    return allowDemoLogin != null ||
        geocodingPrecision != null ||
        backupDays != null ||
        allowSignup != null ||
        signupCredits != null;
  }

  static String retentionLabelFromDays(int days) {
    if (days <= 30) return '1 Month';
    if (days <= 90) return '3 Months';
    if (days <= 180) return '6 Months';
    return '12 Months';
  }

  static int daysFromRetentionLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.startsWith('1')) return 30;
    if (normalized.startsWith('3')) return 90;
    if (normalized.startsWith('6')) return 180;
    if (normalized.startsWith('12')) return 365;
    return 90;
  }

  Map<String, dynamic> toPatchPayload({
    bool? allowDemoLogin,
    int? geocodingPrecision,
    String? backupRetention,
    bool? allowSignup,
    int? signupCredits,
  }) {
    final payload = <String, dynamic>{};

    if (allowDemoLogin != null) {
      payload['allowDemoLogin'] = allowDemoLogin;
    }

    if (geocodingPrecision != null) {
      payload['geocodingPrecision'] = geocodingPrecision >= 3
          ? 'THREE_DIGIT'
          : 'TWO_DIGIT';
    }

    if (backupRetention != null && backupRetention.trim().isNotEmpty) {
      payload['backupDays'] = daysFromRetentionLabel(backupRetention);
    }

    if (allowSignup != null) {
      payload['allowSignup'] = allowSignup;
    }

    if (signupCredits != null) {
      payload['signupCredits'] = signupCredits;
    }

    return payload;
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
