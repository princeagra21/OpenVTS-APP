class ApiConfigData {
  final Map<String, dynamic> raw;

  const ApiConfigData(this.raw);

  bool get isOpenAiEnabled => _b(raw['isOpenAiEnabled']);
  String get openAiApiKey => _s(raw['openAiApiKey']);
  String get openAiModel => _s(raw['openAiModel']);

  bool get isGoogleSsoEnabled => _b(raw['isGoogleSsoEnabled']);
  String get googleClientId => _s(raw['googleClientId']);
  String get googleClientSecret => _s(raw['googleClientSecret']);
  String get googleRedirectUri => _s(raw['googleRedirectUri']);

  bool get isReverseGeoEnabled => _b(raw['isReverseGeoEnabled']);
  String get reverseGeoApiKey => _s(raw['reverseGeoApiKey']);
  String get reverseGeoProvider => _s(raw['reverseGeoProvider']);

  static String _s(Object? v) => v == null ? '' : v.toString();

  static bool _b(Object? v) {
    if (v is bool) return v;
    final s = _s(v).toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
}
