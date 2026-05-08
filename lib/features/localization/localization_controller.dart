import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/common_repository.dart';
import 'package:open_vts/features/localization/localization_models.dart';
import 'package:open_vts/features/localization/localization_repository.dart';
import 'package:open_vts/features/localization/localization_role_config.dart';
import 'package:open_vts/main.dart' show themeController;

class LocalizationController extends ChangeNotifier {
  LocalizationController({required this.config, required this.repository}) {
    _loadedSnapshot = _defaultsSnapshot();
    _syncCoordinateControllers();
    _latController.addListener(_onCoordinateFieldChanged);
    _lngController.addListener(_onCoordinateFieldChanged);
    _zoomController.addListener(_onCoordinateFieldChanged);
  }

  final LocalizationRoleConfig config;
  final LocalizationRepository repository;

  final DateTime previewDate = DateTime(2025, 12, 7, 15, 28);
  final List<String> _months = const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  bool _apiUnavailableShown = false;
  bool _syncingCoordinateControllers = false;

  DateTime? _lastSaveAt;
  CancelToken? _loadToken;
  CancelToken? _saveToken;

  List<ReferenceOption> _languages = const [];
  List<String> _dateFormats = const [];
  List<String> _timezones = const [];

  String _selectedLanguage = '';
  String _textDirection = 'LTR';
  String _dateFormat = '';
  String _timeFormat = '24-hour';
  String _timezone = '';
  String _units = 'KM';
  double _lat = 0;
  double _lng = 0;
  int _zoom = 10;

  LocalizationSnapshot? _loadedSnapshot;

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();

  bool get loading => _loading;
  bool get saving => _saving;
  bool get requireDirtyBeforeSave => config.permissions.requireDirtyBeforeSave;

  List<ReferenceOption> get languages => _languages;
  List<String> get dateFormats => _dateFormats;
  List<String> get timezones => _timezones;

  String get selectedLanguage => _selectedLanguage;
  String get textDirection => _textDirection;
  String get dateFormat => _dateFormat;
  String get timeFormat => _timeFormat;
  String get timezone => _timezone;
  String get units => _units;
  double get lat => _lat;
  double get lng => _lng;
  int get zoom => _zoom;

  TextEditingController get latController => _latController;
  TextEditingController get lngController => _lngController;
  TextEditingController get zoomController => _zoomController;

  bool get isDirty {
    final loaded = _loadedSnapshot;
    if (loaded == null) {
      return false;
    }
    return _captureCurrentSnapshot() != loaded;
  }

  bool get saveDisabled {
    if (_saving || _loading) {
      return true;
    }
    if (requireDirtyBeforeSave && !isDirty) {
      return true;
    }
    return false;
  }

  String getFormattedDate() {
    final day = previewDate.day.toString().padLeft(2, '0');
    final month = previewDate.month.toString().padLeft(2, '0');
    final year = previewDate.year.toString();
    final monthName = _months[previewDate.month];

    return switch (_dateFormat) {
      'dd MMM yyyy' || 'DD MMM YYYY' => '$day $monthName $year',
      'MM/dd/yyyy' || 'MM/DD/YYYY' => '$month/$day/$year',
      'yyyy-MM-dd' || 'YYYY-MM-DD' => '$year-$month-$day',
      _ => '$day $monthName $year',
    };
  }

  String getFormattedTime() {
    final minute = previewDate.minute.toString().padLeft(2, '0');
    if (_timeFormat == '24-hour') {
      return '${previewDate.hour.toString().padLeft(2, '0')}:$minute';
    }

    final hour = previewDate.hour % 12 == 0 ? 12 : previewDate.hour % 12;
    final ampm = previewDate.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  void setSelectedLanguage(String value) {
    _selectedLanguage = value;
    notifyListeners();
  }

  Future<void> setTextDirection(String value) async {
    _textDirection = value == 'RTL' ? 'RTL' : 'LTR';
    notifyListeners();
    await themeController.setTextDirection(_textDirection);
  }

  void setDateFormat(String value) {
    _dateFormat = value;
    notifyListeners();
  }

  void setTimeFormat(String value) {
    _timeFormat = value == '12-hour' ? '12-hour' : '24-hour';
    notifyListeners();
  }

  void setTimezone(String value) {
    _timezone = value;
    notifyListeners();
  }

  Future<void> setUnits(String value) async {
    _units = value == 'MILES' ? 'MILES' : 'KM';
    notifyListeners();
    await themeController.setUnits(_units);
  }

  void applyPreset(double lat, double lng) {
    _lat = lat;
    _lng = lng;
    _syncCoordinateControllers();
    notifyListeners();
  }

  void reset() {
    final snapshot = _loadedSnapshot ?? _defaultsSnapshot();
    _applySnapshot(snapshot);
    _syncCoordinateControllers();
    notifyListeners();
    _syncGlobalSettings();
  }

  Future<void> setThemeMode(String mode) async {
    if (mode == 'dark') {
      await themeController.setThemeMode(ThemeMode.dark);
      return;
    }
    if (mode == 'light') {
      await themeController.setThemeMode(ThemeMode.light);
      return;
    }
    await themeController.setThemeMode(ThemeMode.system);
  }

  Future<String?> loadLocalizationData() async {
    _loadToken?.cancel('Reload localization');
    final token = CancelToken();
    _loadToken = token;

    _loading = true;
    notifyListeners();

    var nextLanguages = List<ReferenceOption>.from(_languages);
    var nextDateFormats = List<String>.from(_dateFormats);
    var nextTimezones = List<String>.from(_timezones);

    var nextSelectedLanguage = _selectedLanguage;
    var nextTextDirection = _textDirection;
    var nextDateFormat = _dateFormat;
    var nextTimeFormat = _timeFormat;
    var nextTimezone = _timezone;
    var nextUnits = _units;
    var nextLat = _lat;
    var nextLng = _lng;
    var nextZoom = _zoom;

    LocalizationSnapshot? nextSnapshot = _loadedSnapshot;
    String? firstErrorMessage;

    try {
      final languagesResult = await repository.getLanguages(cancelToken: token);
      languagesResult.when(
        success: (items) {
          nextLanguages = _optionsOrFallbackOptions(items, _languages);
        },
        failure: (err) {
          firstErrorMessage ??= _resolveLoadErrorMessage(
            err,
            unauthorizedMessage: 'Not authorized to load reference data.',
            fallbackMessage: "Couldn't load localization reference data.",
          );
        },
      );

      final dateFormatsResult = await repository.getDateFormats(
        cancelToken: token,
      );
      dateFormatsResult.when(
        success: (items) {
          nextDateFormats = _optionsOrFallback(items, _dateFormats);
        },
        failure: (err) {
          firstErrorMessage ??= _resolveLoadErrorMessage(
            err,
            unauthorizedMessage: 'Not authorized to load reference data.',
            fallbackMessage: "Couldn't load localization reference data.",
          );
        },
      );

      final timezonesResult = await repository.getTimezones(cancelToken: token);
      timezonesResult.when(
        success: (items) {
          nextTimezones = _optionsOrFallback(items, _timezones);
        },
        failure: (err) {
          firstErrorMessage ??= _resolveLoadErrorMessage(
            err,
            unauthorizedMessage: 'Not authorized to load reference data.',
            fallbackMessage: "Couldn't load localization reference data.",
          );
        },
      );

      if (config.permissions.hasLocalizationSettingsEndpoint) {
        final settingsResult = await repository.getLocalization(
          cancelToken: token,
        );

        settingsResult.when(
          success: (settings) {
            nextLanguages = _ensureOptionContains(
              nextLanguages,
              settings.languageCode,
              label: settings.languageCode,
            );
            nextDateFormats = _ensureContains(
              nextDateFormats,
              settings.dateFormat,
            );
            nextTimezones = _ensureContains(nextTimezones, settings.timezone);

            nextSelectedLanguage = _matchLanguageChoice(
              settings.languageCode,
              nextLanguages,
              nextSelectedLanguage,
            );
            nextTextDirection = _normalizeDirection(
              settings.direction,
              nextTextDirection,
            );
            nextDateFormat = _matchChoice(
              settings.dateFormat,
              nextDateFormats,
              nextDateFormat,
            );

            final use24 = settings.use24Hour;
            if (use24 != null) {
              nextTimeFormat = use24 ? '24-hour' : '12-hour';
            } else {
              final tf = settings.timeFormat.toLowerCase();
              if (tf.contains('12')) {
                nextTimeFormat = '12-hour';
              } else if (tf.contains('24')) {
                nextTimeFormat = '24-hour';
              }
            }

            nextTimezone = _matchChoice(
              settings.timezone,
              nextTimezones,
              nextTimezone,
            );
            nextUnits = _normalizeUnits(settings.units, nextUnits);

            if (settings.mapLat != null) {
              nextLat = settings.mapLat!;
            }
            if (settings.mapLng != null) {
              nextLng = settings.mapLng!;
            }
            if (settings.mapZoom != null &&
                settings.mapZoom! >= 1 &&
                settings.mapZoom! <= 22) {
              nextZoom = settings.mapZoom!;
            }

            nextSnapshot = LocalizationSnapshot(
              selectedLanguage: nextSelectedLanguage,
              textDirection: nextTextDirection,
              dateFormat: nextDateFormat,
              timeFormat: nextTimeFormat,
              timezone: nextTimezone,
              units: nextUnits,
              lat: nextLat,
              lng: nextLng,
              zoom: nextZoom,
            );

            _loadErrorShown = false;
          },
          failure: (err) {
            firstErrorMessage ??= _resolveLoadErrorMessage(
              err,
              unauthorizedMessage:
                  'Not authorized to load localization settings.',
              fallbackMessage: "Couldn't load localization settings.",
            );
          },
        );
      }
    } catch (_) {
      firstErrorMessage ??= _resolveLoadErrorMessage(
        null,
        unauthorizedMessage: "Couldn't load localization data.",
        fallbackMessage: "Couldn't load localization data.",
      );
    }

    _loading = false;
    _languages = nextLanguages;
    _dateFormats = nextDateFormats;
    _timezones = nextTimezones;

    final languageFallback = config.permissions.preferEnglishDefaultLanguage
        ? _firstOrEnglish(_languages)
        : _firstOrEmptyLanguage(_languages);

    _selectedLanguage = _matchLanguageChoice(
      nextSelectedLanguage,
      _languages,
      languageFallback,
    );

    if (config.permissions.preferEnglishDefaultLanguage &&
        _selectedLanguage.trim().isEmpty) {
      _selectedLanguage = languageFallback;
    }

    _textDirection = nextTextDirection;
    _dateFormat = _matchChoice(
      nextDateFormat,
      _dateFormats,
      _firstOrEmpty(_dateFormats),
    );
    _timeFormat = nextTimeFormat;
    _timezone = _matchChoice(
      nextTimezone,
      _timezones,
      _firstOrEmpty(_timezones),
    );
    _units = nextUnits;
    _lat = nextLat;
    _lng = nextLng;
    _zoom = nextZoom;

    _loadedSnapshot ??= _defaultsSnapshot();
    if (nextSnapshot != null) {
      _loadedSnapshot = nextSnapshot;
    }

    _syncCoordinateControllers();
    notifyListeners();
    await _syncGlobalSettings();

    return firstErrorMessage;
  }

  Future<LocalizationSaveResult> saveLocalization({
    bool showSuccess = true,
  }) async {
    if (!config.permissions.hasLocalizationSettingsEndpoint) {
      if (!_apiUnavailableShown) {
        _apiUnavailableShown = true;
        return const LocalizationSaveResult.failure('API not available yet');
      }
      return const LocalizationSaveResult.idle();
    }

    if (_saving) {
      return const LocalizationSaveResult.idle();
    }

    if (config.permissions.requireDirtyBeforeSave && !isDirty) {
      return const LocalizationSaveResult.idle();
    }

    final now = DateTime.now();
    final last = _lastSaveAt;
    if (last != null && now.difference(last).inMilliseconds < 800) {
      return const LocalizationSaveResult.idle();
    }
    _lastSaveAt = now;

    _saveToken?.cancel('Retry localization save');
    final token = CancelToken();
    _saveToken = token;

    _saving = true;
    notifyListeners();

    final payload = <String, dynamic>{
      'language': _selectedLanguage,
      'dateFormat': _dateFormat,
      'use24Hour': _timeFormat == '24-hour',
      'layoutDirection': _textDirection,
      'timezoneOffset': _timezone,
      'units': _units,
      'defaultLat': _lat.toStringAsFixed(6),
      'defaultLon': _lng.toStringAsFixed(6),
      'mapZoom': _zoom.toString(),
    };

    if (config.permissions.includeThemeInPayload) {
      payload['theme'] = themeController.themeMode.value == ThemeMode.dark
          ? 'DARK'
          : 'LIGHT';
    }

    try {
      final result = await repository.updateLocalization(
        payload,
        cancelToken: token,
      );

      return result.when(
        success: (_) async {
          _saving = false;
          _saveErrorShown = false;
          _loadedSnapshot = _captureCurrentSnapshot();
          notifyListeners();
          await _syncGlobalSettings();
          return showSuccess
              ? LocalizationSaveResult.success(config.saveSuccessMessage)
              : const LocalizationSaveResult.idle();
        },
        failure: (err) {
          _saving = false;
          notifyListeners();

          if (_saveErrorShown) {
            return const LocalizationSaveResult.idle();
          }
          _saveErrorShown = true;

          final message =
              err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403)
              ? 'Not authorized to save localization settings.'
              : (err is ApiException &&
                        config.role == LocalizationRole.superadmin &&
                        err.message.trim().isNotEmpty
                    ? err.message
                    : "Couldn't save localization settings.");

          return LocalizationSaveResult.failure(message);
        },
      );
    } catch (_) {
      _saving = false;
      notifyListeners();

      if (_saveErrorShown) {
        return const LocalizationSaveResult.idle();
      }
      _saveErrorShown = true;
      return const LocalizationSaveResult.failure(
        "Couldn't save localization settings.",
      );
    }
  }

  @override
  void dispose() {
    _loadToken?.cancel('Localization disposed');
    _saveToken?.cancel('Localization disposed');
    _latController
      ..removeListener(_onCoordinateFieldChanged)
      ..dispose();
    _lngController
      ..removeListener(_onCoordinateFieldChanged)
      ..dispose();
    _zoomController
      ..removeListener(_onCoordinateFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _onCoordinateFieldChanged() {
    if (_syncingCoordinateControllers) {
      return;
    }

    final parsedLat = double.tryParse(_latController.text.trim());
    final parsedLng = double.tryParse(_lngController.text.trim());
    final parsedZoom = int.tryParse(_zoomController.text.trim());

    var changed = false;
    if (parsedLat != null && parsedLat != _lat) {
      _lat = parsedLat;
      changed = true;
    }
    if (parsedLng != null && parsedLng != _lng) {
      _lng = parsedLng;
      changed = true;
    }
    if (parsedZoom != null && parsedZoom != _zoom) {
      _zoom = parsedZoom;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<void> _syncGlobalSettings() async {
    await themeController.setTextDirection(_textDirection);
    await themeController.setUnits(_units);
  }

  LocalizationSnapshot _defaultsSnapshot() {
    return LocalizationSnapshot(
      selectedLanguage: config.permissions.preferEnglishDefaultLanguage
          ? 'en'
          : '',
      textDirection: 'LTR',
      dateFormat: '',
      timeFormat: '24-hour',
      timezone: '',
      units: 'KM',
      lat: 0,
      lng: 0,
      zoom: 10,
    );
  }

  LocalizationSnapshot _captureCurrentSnapshot() {
    return LocalizationSnapshot(
      selectedLanguage: _selectedLanguage,
      textDirection: _textDirection,
      dateFormat: _dateFormat,
      timeFormat: _timeFormat,
      timezone: _timezone,
      units: _units,
      lat: _lat,
      lng: _lng,
      zoom: _zoom,
    );
  }

  void _applySnapshot(LocalizationSnapshot snapshot) {
    _selectedLanguage = snapshot.selectedLanguage;
    _textDirection = snapshot.textDirection;
    _dateFormat = snapshot.dateFormat;
    _timeFormat = snapshot.timeFormat;
    _timezone = snapshot.timezone;
    _units = snapshot.units;
    _lat = snapshot.lat;
    _lng = snapshot.lng;
    _zoom = snapshot.zoom;
  }

  void _syncCoordinateControllers() {
    _syncingCoordinateControllers = true;
    _latController.text = _lat.toStringAsFixed(6);
    _lngController.text = _lng.toStringAsFixed(6);
    _zoomController.text = _zoom.toString();
    _syncingCoordinateControllers = false;
  }

  String _resolveLoadErrorMessage(
    Object? error, {
    required String unauthorizedMessage,
    required String fallbackMessage,
  }) {
    if (_loadErrorShown) {
      return fallbackMessage;
    }

    _loadErrorShown = true;
    if (error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return unauthorizedMessage;
    }
    return fallbackMessage;
  }

  String _normalizeDirection(String raw, String fallback) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'RTL') return 'RTL';
    if (normalized == 'LTR') return 'LTR';
    return fallback;
  }

  String _normalizeUnits(String raw, String fallback) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'KM' ||
        normalized == 'KMS' ||
        normalized == 'KILOMETERS') {
      return 'KM';
    }
    if (normalized == 'MILE' || normalized == 'MILES' || normalized == 'MI') {
      return 'MILES';
    }
    return fallback;
  }

  String _matchChoice(String value, List<String> options, String fallback) {
    if (value.trim().isEmpty) {
      return fallback;
    }

    for (final option in options) {
      if (option.toLowerCase() == value.toLowerCase()) {
        return option;
      }
    }
    return fallback;
  }

  String _matchLanguageChoice(
    String value,
    List<ReferenceOption> options,
    String fallback,
  ) {
    if (value.trim().isEmpty) {
      return fallback;
    }

    for (final option in options) {
      if (option.value.toLowerCase() == value.toLowerCase()) {
        return option.value;
      }
    }
    return fallback;
  }

  List<ReferenceOption> _optionsOrFallbackOptions(
    List<ReferenceOption> values,
    List<ReferenceOption> fallback,
  ) {
    final out = <ReferenceOption>[];
    final seen = <String>{};

    for (final item in values) {
      final value = item.value.trim();
      final label = item.label.trim();
      if (value.isEmpty && label.isEmpty) {
        continue;
      }

      final key = value.isEmpty ? label.toLowerCase() : value.toLowerCase();
      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);
      out.add(
        ReferenceOption(value: value, label: label.isEmpty ? value : label),
      );
    }

    if (out.isEmpty) {
      return List<ReferenceOption>.from(fallback);
    }
    return out;
  }

  List<String> _optionsOrFallback(List<String> values, List<String> fallback) {
    final out = <String>[];
    final seen = <String>{};

    for (final item in values) {
      final normalized = item.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final key = normalized.toLowerCase();
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      out.add(normalized);
    }

    if (out.isEmpty) {
      return List<String>.from(fallback);
    }
    return out;
  }

  List<ReferenceOption> _ensureOptionContains(
    List<ReferenceOption> values,
    String current, {
    String? label,
  }) {
    final code = current.trim();
    if (code.isEmpty) {
      return values;
    }

    final has = values.any(
      (item) => item.value.toLowerCase() == code.toLowerCase(),
    );
    if (has) {
      return values;
    }

    return [
      ...values,
      ReferenceOption(
        value: code,
        label: (label == null || label.trim().isEmpty) ? code : label.trim(),
      ),
    ];
  }

  List<String> _ensureContains(List<String> values, String current) {
    if (current.trim().isEmpty) {
      return values;
    }

    final has = values.any(
      (item) => item.toLowerCase() == current.toLowerCase(),
    );
    if (has) {
      return values;
    }

    return [...values, current];
  }

  String _firstOrEnglish(List<ReferenceOption> values) {
    if (values.isEmpty) {
      return '';
    }

    for (final option in values) {
      if (option.value.toLowerCase() == 'en') {
        return option.value;
      }
      if (option.label.toLowerCase() == 'english') {
        return option.value;
      }
    }

    return values.first.value;
  }

  String _firstOrEmptyLanguage(List<ReferenceOption> values) {
    if (values.isEmpty) {
      return '';
    }
    return values.first.value;
  }

  String _firstOrEmpty(List<String> values) {
    if (values.isEmpty) {
      return '';
    }
    return values.first;
  }
}
