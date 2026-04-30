import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiBaseUrlConfig extends ChangeNotifier {
  ApiBaseUrlConfig._();

  static final ApiBaseUrlConfig instance = ApiBaseUrlConfig._();

  static const String _storageKey = 'custom_api_base_url';

  final ValueNotifier<String> effectiveBaseUrlNotifier =
      ValueNotifier<String>(_normalizeBaseUrl(_defaultBaseUrl) ?? _defaultBaseUrl);

  String? _customBaseUrl;
  bool _loaded = false;

  static String get _defaultBaseUrl => String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://app.openvts.io/api',
      );

  String get defaultBaseUrl => _defaultBaseUrl;

  String get effectiveBaseUrl {
    final custom = _customBaseUrl?.trim() ?? '';
    final fallback = _normalizeBaseUrl(_defaultBaseUrl) ?? _defaultBaseUrl;
    return custom.isNotEmpty ? custom : fallback;
  }

  bool get hasCustomBaseUrl => (_customBaseUrl?.trim().isNotEmpty ?? false);

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _normalizeBaseUrl(prefs.getString(_storageKey));
    _customBaseUrl = saved;
    _loaded = true;
    effectiveBaseUrlNotifier.value = effectiveBaseUrl;
    notifyListeners();
  }

  Future<void> setCustomBaseUrl(String url) async {
    final normalized = _normalizeBaseUrl(url);
    if (normalized == null) {
      throw const FormatException('Invalid API base URL.');
    }

    _customBaseUrl = normalized;
    _loaded = true;
    effectiveBaseUrlNotifier.value = effectiveBaseUrl;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, normalized);
  }

  Future<void> resetBaseUrl() async {
    _customBaseUrl = null;
    _loaded = true;
    effectiveBaseUrlNotifier.value = effectiveBaseUrl;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  String? normalizeInput(String? raw) => _normalizeBaseUrl(raw);

  Future<bool> testConnection(String rawBaseUrl) async {
    final normalized = _normalizeBaseUrl(rawBaseUrl);
    if (normalized == null) return false;

    final dio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        validateStatus: (_) => true,
        headers: const {'Accept': 'application/json'},
      ),
    );

    try {
      await dio.get<dynamic>('');
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? _normalizeBaseUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!(value.startsWith('http://') || value.startsWith('https://'))) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.trim().isEmpty) return null;

    var normalized = value;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
