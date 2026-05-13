class ApiConfigModel {
  const ApiConfigModel({
    required this.firebaseEnabled,
    required this.firebaseApiKey,
    required this.firebaseAuthDomain,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
    required this.firebaseMessagingSenderId,
    required this.firebaseAppId,
    required this.firebaseMeasurementId,
    required this.geocodingEnabled,
    required this.geocodingProvider,
    required this.geocodingApiKey,
    required this.geocodingUserAgent,
    required this.geocodingProviderActive,
    required this.googleSsoEnabled,
    required this.googleClientId,
    required this.googleClientSecret,
    required this.googleRedirectUrl,
    required this.openaiEnabled,
    required this.openaiApiKey,
    required this.openaiOrgId,
    required this.openaiModel,
    required this.openaiMaxTokens,
  });

  factory ApiConfigModel.fromMap(Map<String, dynamic> map) {
    return ApiConfigModel(
      firebaseEnabled: _pickBool(map, [
        'firebaseEnabled',
        'firebaseConfigEnabled',
        'isFirebaseEnabled',
      ]) ?? false,
      firebaseApiKey: _pickString(map, ['firebaseApiKey', 'apiKey']),
      firebaseAuthDomain: _pickString(map, ['firebaseAuthDomain', 'authDomain']),
      firebaseProjectId: _pickString(map, ['firebaseProjectId', 'projectId']),
      firebaseStorageBucket: _pickString(map, ['firebaseStorageBucket', 'storageBucket']),
      firebaseMessagingSenderId: _pickString(map, ['firebaseMessagingSenderId', 'messagingSenderId']),
      firebaseAppId: _pickString(map, ['firebaseAppId', 'appId']),
      firebaseMeasurementId: _pickString(map, ['firebaseMeasurementId', 'measurementId']),
      geocodingEnabled: _pickBool(map, ['geocodingEnabled', 'isReverseGeoEnabled']) ?? false,
      geocodingProvider: _pickString(map, ['geocodingProvider', 'reverseGeoProvider']),
      geocodingApiKey: _pickString(map, ['reverseGeoApiKey', 'geocodingApiKey']),
      geocodingUserAgent: _pickString(map, ['geocodingUserAgent', 'userAgent']),
      geocodingProviderActive: _pickBool(map, [
        'geocodingProviderActive',
        'reverseGeoProviderActive',
        'providerActive',
      ]) ?? false,
      googleSsoEnabled: _pickBool(map, ['googleSsoEnabled', 'isGoogleSsoEnabled']) ?? false,
      googleClientId: _pickString(map, ['googleClientId']),
      googleClientSecret: _pickString(map, ['googleClientSecret']),
      googleRedirectUrl: _pickString(map, ['googleRedirectUrl']),
      openaiEnabled: _pickBool(map, ['openaiEnabled', 'isOpenAiEnabled']) ?? false,
      openaiApiKey: _pickString(map, ['openaiApiKey']),
      openaiOrgId: _pickString(map, ['openaiOrgId']),
      openaiModel: _pickString(map, ['openaiModel']),
      openaiMaxTokens: _pickInt(map, ['openaiMaxTokens']) ?? 2048,
    );
  }

  final bool firebaseEnabled;
  final String firebaseApiKey;
  final String firebaseAuthDomain;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final String firebaseMessagingSenderId;
  final String firebaseAppId;
  final String firebaseMeasurementId;
  final bool geocodingEnabled;
  final String geocodingProvider;
  final String geocodingApiKey;
  final String geocodingUserAgent;
  final bool geocodingProviderActive;
  final bool googleSsoEnabled;
  final String googleClientId;
  final String googleClientSecret;
  final String googleRedirectUrl;
  final bool openaiEnabled;
  final String openaiApiKey;
  final String openaiOrgId;
  final String openaiModel;
  final int openaiMaxTokens;

  Map<String, dynamic> toMap() {
    return {
      'firebaseEnabled': firebaseEnabled,
      'firebaseApiKey': firebaseApiKey,
      'firebaseAuthDomain': firebaseAuthDomain,
      'firebaseProjectId': firebaseProjectId,
      'firebaseStorageBucket': firebaseStorageBucket,
      'firebaseMessagingSenderId': firebaseMessagingSenderId,
      'firebaseAppId': firebaseAppId,
      'firebaseMeasurementId': firebaseMeasurementId,
      'geocodingEnabled': geocodingEnabled,
      'geocodingProvider': geocodingProvider,
      'reverseGeoApiKey': geocodingApiKey,
      'geocodingUserAgent': geocodingUserAgent,
      'geocodingProviderActive': geocodingProviderActive,
      'googleSsoEnabled': googleSsoEnabled,
      'googleClientId': googleClientId,
      'googleClientSecret': googleClientSecret,
      'googleRedirectUrl': googleRedirectUrl,
      'openaiEnabled': openaiEnabled,
      'openaiApiKey': openaiApiKey,
      'openaiOrgId': openaiOrgId,
      'openaiModel': openaiModel,
      'openaiMaxTokens': openaiMaxTokens,
    };
  }

  static Object? _pickRaw(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) return map[key];
    }
    return null;
  }

  static String _pickString(Map<String, dynamic> map, List<String> keys) {
    final value = _pickRaw(map, keys);
    return value == null ? '' : value.toString().trim();
  }

  static bool? _pickBool(Map<String, dynamic> map, List<String> keys) {
    final value = _pickRaw(map, keys);
    if (value == null) return null;
    if (value is bool) return value;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  static int? _pickInt(Map<String, dynamic> map, List<String> keys) {
    final value = _pickRaw(map, keys);
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }
}

class ApiConfigState {
  const ApiConfigState({
    required this.config,
    required this.isLoading,
    required this.isSaving,
    required this.testStates,
    required this.lastSaveAt,
    required this.errorMessage,
  });

  const ApiConfigState.initial()
    : config = const ApiConfigModel(
        firebaseEnabled: false,
        firebaseApiKey: '',
        firebaseAuthDomain: '',
        firebaseProjectId: '',
        firebaseStorageBucket: '',
        firebaseMessagingSenderId: '',
        firebaseAppId: '',
        firebaseMeasurementId: '',
        geocodingEnabled: false,
        geocodingProvider: '',
        geocodingApiKey: '',
        geocodingUserAgent: '',
        geocodingProviderActive: false,
        googleSsoEnabled: false,
        googleClientId: '',
        googleClientSecret: '',
        googleRedirectUrl: '',
        openaiEnabled: false,
        openaiApiKey: '',
        openaiOrgId: '',
        openaiModel: '',
        openaiMaxTokens: 2048,
      ),
      isLoading = false,
      isSaving = false,
      testStates = const {},
      lastSaveAt = null,
      errorMessage = null;

  final ApiConfigModel config;
  final bool isLoading;
  final bool isSaving;
  final Map<String, bool> testStates;
  final DateTime? lastSaveAt;
  final String? errorMessage;

  ApiConfigState copyWith({
    ApiConfigModel? config,
    bool? isLoading,
    bool? isSaving,
    Map<String, bool>? testStates,
    DateTime? lastSaveAt,
    String? errorMessage,
  }) {
    return ApiConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      testStates: testStates ?? this.testStates,
      lastSaveAt: lastSaveAt ?? this.lastSaveAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
