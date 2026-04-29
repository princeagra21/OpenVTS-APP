// screens/settings/localization_settings_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/theme/app_theme.dart';
import 'package:fleet_stack/main.dart' show themeController;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocalizationSettingsScreen extends StatelessWidget {
  const LocalizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Localization",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const LocalizationHeader(), const SizedBox(height: 24)],
        ),
      ),
    );
  }
}

class LocalizationHeader extends StatefulWidget {
  const LocalizationHeader({super.key});

  @override
  State<LocalizationHeader> createState() => _LocalizationHeaderState();
}

class _LocalizationHeaderState extends State<LocalizationHeader> {
  // Postman-confirmed endpoints:
  // - GET /languages
  // - GET /timezones
  // - GET /dateformats
  // - GET /superadmin/localization
  // - PATCH /superadmin/localization
  final bool _hasLocalizationSettingsEndpoint = true;

  String selectedLanguage = '';
  String textDirection = "LTR";
  String dateFormat = '';
  String timeFormat = "24-hour";
  String timezone = '';
  String units = "KM";
  double lat = 0;
  double lng = 0;
  int zoom = 10;

  final DateTime previewDate = DateTime(2025, 12, 7, 15, 28);
  final List<String> months = [
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

  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _zoomController;

  List<String> _languages = const [];
  List<ReferenceOption> _languageOptions = const [];
  List<String> _dateFormats = const [];
  List<String> _timezones = const [];

  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  bool _apiUnavailableShown = false;
  DateTime? _lastSaveAt;

  CancelToken? _loadToken;
  CancelToken? _saveToken;

  ApiClient? _apiClient;
  CommonRepository? _commonRepo;
  SuperadminRepository? _superadminRepo;

  _LocalizationSnapshot? _loadedSnapshot;

  CommonRepository _commonRepoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _apiClient!);
    return _commonRepo!;
  }

  SuperadminRepository _superRepoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _superadminRepo ??= SuperadminRepository(api: _apiClient!);
    return _superadminRepo!;
  }

  bool get _isDirty {
    if (_loadedSnapshot == null) return false;
    final current = _captureCurrentSnapshot();
    return current.selectedLanguage != _loadedSnapshot!.selectedLanguage ||
        current.textDirection != _loadedSnapshot!.textDirection ||
        current.dateFormat != _loadedSnapshot!.dateFormat ||
        current.timeFormat != _loadedSnapshot!.timeFormat ||
        current.timezone != _loadedSnapshot!.timezone ||
        current.units != _loadedSnapshot!.units ||
        current.lat != _loadedSnapshot!.lat ||
        current.lng != _loadedSnapshot!.lng ||
        current.zoom != _loadedSnapshot!.zoom;
  }

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(text: lat.toString());
    _lngController = TextEditingController(text: lng.toString());
    _zoomController = TextEditingController(text: zoom.toString());

    _latController.addListener(() => setState(() {}));
    _lngController.addListener(() => setState(() {}));
    _zoomController.addListener(() => setState(() {}));

    _loadedSnapshot = _defaultsSnapshot();
    _loadLocalizationData();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Localization disposed');
    _saveToken?.cancel('Localization disposed');
    _latController.dispose();
    _lngController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  String getFormattedDate() {
    String day = previewDate.day.toString().padLeft(2, '0');
    String month = previewDate.month.toString().padLeft(2, '0');
    String year = previewDate.year.toString();
    String monthName = months[previewDate.month];

    return switch (dateFormat) {
      "dd MMM yyyy" || "DD MMM YYYY" => "$day $monthName $year",
      "MM/dd/yyyy" || "MM/DD/YYYY" => "$month/$day/$year",
      "yyyy-MM-dd" || "YYYY-MM-DD" => "$year-$month-$day",
      _ => "$day $monthName $year",
    };
  }

  String getFormattedTime() {
    String minute = previewDate.minute.toString().padLeft(2, '0');
    if (timeFormat == "24-hour") {
      return "${previewDate.hour.toString().padLeft(2, '0')}:$minute";
    } else {
      int hour = previewDate.hour % 12 == 0 ? 12 : previewDate.hour % 12;
      String ampm = previewDate.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $ampm";
    }
  }

  _LocalizationSnapshot _defaultsSnapshot() {
    return const _LocalizationSnapshot(
      selectedLanguage: '',
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

  _LocalizationSnapshot _captureCurrentSnapshot() {
    return _LocalizationSnapshot(
      selectedLanguage: selectedLanguage,
      textDirection: textDirection,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      timezone: timezone,
      units: units,
      lat: lat,
      lng: lng,
      zoom: zoom,
    );
  }

  void _applySnapshot(_LocalizationSnapshot snapshot) {
    selectedLanguage = snapshot.selectedLanguage;
    textDirection = snapshot.textDirection;
    dateFormat = snapshot.dateFormat;
    timeFormat = snapshot.timeFormat;
    timezone = snapshot.timezone;
    units = snapshot.units;
    lat = snapshot.lat;
    lng = snapshot.lng;
    zoom = snapshot.zoom;
  }

  Future<void> _syncGlobalSettings() async {
    await themeController.setTextDirection(textDirection);
    await themeController.setUnits(units);
  }

  Future<void> _setThemeMode(String mode) async {
    if (!mounted) return;
    if (mode == 'dark') {
      themeController.setThemeMode(ThemeMode.dark);
      await AppTheme.setDarkMode(true);
      return;
    }
    if (mode == 'light') {
      themeController.setThemeMode(ThemeMode.light);
      await AppTheme.setDarkMode(false);
      return;
    }
    themeController.setThemeMode(ThemeMode.system);
    final isDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    await AppTheme.setDarkMode(isDark);
  }

  void _showLoadErrorOnce(String message) {
    if (_loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _normalizeDirection(String raw, String fallback) {
    final v = raw.trim().toUpperCase();
    if (v == 'RTL') return 'RTL';
    if (v == 'LTR') return 'LTR';
    return fallback;
  }

  String _normalizeUnits(String raw, String fallback) {
    final v = raw.trim().toUpperCase();
    if (v == 'KM' || v == 'KMS' || v == 'KILOMETERS') return 'KM';
    if (v == 'MILE' || v == 'MILES' || v == 'MI') return 'MILES';
    return fallback;
  }

  String _matchChoice(String value, List<String> options, String fallback) {
    if (value.trim().isEmpty) return fallback;
    for (final option in options) {
      if (option.toLowerCase() == value.toLowerCase()) {
        return option;
      }
    }
    return fallback;
  }

  List<String> _optionsOrFallback(List<String> values, List<String> fallback) {
    final out = <String>[];
    final seen = <String>{};
    for (final v in values) {
      final normalized = v.trim();
      if (normalized.isEmpty) continue;
      final key = normalized.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(normalized);
    }
    if (out.isEmpty) return List<String>.from(fallback);
    return out;
  }

  List<String> _ensureContains(List<String> values, String current) {
    if (current.trim().isEmpty) return values;
    final has = values.any((e) => e.toLowerCase() == current.toLowerCase());
    if (has) return values;
    return [...values, current];
  }

  List<ReferenceOption> _optionsOrFallbackOptions(
    List<ReferenceOption> values,
    List<ReferenceOption> fallback,
  ) {
    final out = <ReferenceOption>[];
    final seen = <String>{};
    for (final v in values) {
      final code = v.value.trim();
      final label = v.label.trim();
      if (code.isEmpty && label.isEmpty) continue;
      final key = code.isEmpty ? label.toLowerCase() : code.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(ReferenceOption(value: code, label: label.isEmpty ? code : label));
    }
    if (out.isEmpty) return List<ReferenceOption>.from(fallback);
    return out;
  }

  List<ReferenceOption> _ensureLanguageOptionContains(
    List<ReferenceOption> values,
    String current, {
    String? label,
  }) {
    final code = current.trim();
    if (code.isEmpty) return values;
    final has = values.any((e) => e.value.toLowerCase() == code.toLowerCase());
    if (has) return values;
    return [
      ...values,
      ReferenceOption(
        value: code,
        label: (label == null || label.trim().isEmpty) ? code : label.trim(),
      ),
    ];
  }

  String _firstOrEmpty(List<String> values) {
    if (values.isEmpty) return '';
    return values.first;
  }

  String? _dropdownValueOrNull(List<String> options, String current) {
    if (current.trim().isEmpty) return null;
    final has = options.any((e) => e.toLowerCase() == current.toLowerCase());
    return has ? current : null;
  }

  ReferenceOption? _languageOption(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    for (final option in _languageOptions) {
      if (option.value.toLowerCase() == trimmed.toLowerCase()) {
        return option;
      }
    }
    return null;
  }

  String _languageLabel(String code) {
    final option = _languageOption(code);
    if (option == null) return code.trim().isEmpty ? '—' : code;
    return option.label.trim().isEmpty ? option.value : option.label;
  }

  Future<void> _pickLanguage() async {
    if (_loading || _languageOptions.isEmpty) return;

    final picked = await showModalBottomSheet<ReferenceOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final searchController = TextEditingController();
        String query = '';
        final double fontSize = AdaptiveUtils.getTitleFontSize(
          MediaQuery.of(ctx).size.width,
        );

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = _languageOptions.where((option) {
                  final text =
                      '${option.label} ${option.value}'.toLowerCase().trim();
                  return text.contains(query.toLowerCase().trim());
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select Language',
                              style: GoogleFonts.roboto(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (value) => setSheetState(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Search language',
                          filled: true,
                          fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (_, index) {
                            final option = filtered[index];
                            return ListTile(
                              title: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: fontSize - 1,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx, option),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => selectedLanguage = picked.value);
    }
  }

  Future<void> _loadLocalizationData() async {
    _loadToken?.cancel('Reload localization');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    var nextLanguageOptions = List<ReferenceOption>.from(_languageOptions);
    var nextLanguages = List<String>.from(_languages);
    var nextDateFormats = List<String>.from(_dateFormats);
    var nextTimezones = List<String>.from(_timezones);

    var nextSelectedLanguage = selectedLanguage;
    var nextTextDirection = textDirection;
    var nextDateFormat = dateFormat;
    var nextTimeFormat = timeFormat;
    var nextTimezone = timezone;
    var nextUnits = units;
    var nextLat = lat;
    var nextLng = lng;
    var nextZoom = zoom;

    _LocalizationSnapshot? nextSnapshot = _loadedSnapshot;

    try {
      final commonRepo = _commonRepoOrCreate();

      final languagesRes = await commonRepo.getLanguages(cancelToken: token);
      if (!mounted) return;
      languagesRes.when(
        success: (items) {
          nextLanguageOptions = _optionsOrFallbackOptions(
            items,
            _languageOptions,
          );
          nextLanguages = nextLanguageOptions.map((e) => e.value).toList();
        },
        failure: (err) {
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load reference data.'
              : "Couldn't load localization reference data.";
          _showLoadErrorOnce(message);
        },
      );

      final dateFormatsRes = await commonRepo.getDateFormats(
        cancelToken: token,
      );
      if (!mounted) return;
      dateFormatsRes.when(
        success: (items) {
          final values = items.map((e) => e.value).toList();
          nextDateFormats = _optionsOrFallback(values, _dateFormats);
        },
        failure: (err) {
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load reference data.'
              : "Couldn't load localization reference data.";
          _showLoadErrorOnce(message);
        },
      );

      final timezonesRes = await commonRepo.getTimezones(cancelToken: token);
      if (!mounted) return;
      timezonesRes.when(
        success: (items) {
          final values = items.map((e) => e.value).toList();
          nextTimezones = _optionsOrFallback(values, _timezones);
        },
        failure: (err) {
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load reference data.'
              : "Couldn't load localization reference data.";
          _showLoadErrorOnce(message);
        },
      );

      if (_hasLocalizationSettingsEndpoint) {
        final settingsRes = await _superRepoOrCreate().getLocalizationSettings(
          cancelToken: token,
        );
        if (!mounted) return;

        settingsRes.when(
          success: (settings) {
            nextLanguageOptions = _ensureLanguageOptionContains(
              nextLanguageOptions,
              settings.languageCode,
              label: settings.languageCode,
            );
            nextLanguages = nextLanguageOptions.map((e) => e.value).toList();
            nextDateFormats = _ensureContains(
              nextDateFormats,
              settings.dateFormat,
            );
            nextTimezones = _ensureContains(nextTimezones, settings.timezone);

            nextSelectedLanguage = _matchChoice(
              settings.languageCode,
              nextLanguages,
              nextSelectedLanguage,
            );
            nextTextDirection = _normalizeDirection(
              settings.textDirection,
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
            if (settings.mapLat != null) nextLat = settings.mapLat!;
            if (settings.mapLng != null) nextLng = settings.mapLng!;
            if (settings.mapZoom != null &&
                settings.mapZoom! >= 1 &&
                settings.mapZoom! <= 22) {
              nextZoom = settings.mapZoom!;
            }

            nextSnapshot = _LocalizationSnapshot(
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
            final message =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to load localization settings.'
                : "Couldn't load localization settings.";
            _showLoadErrorOnce(message);
          },
        );
      }
    } catch (_) {
      _showLoadErrorOnce("Couldn't load localization data.");
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _languageOptions = nextLanguageOptions;
      _languages = nextLanguages;
      _dateFormats = nextDateFormats;
      _timezones = nextTimezones;
      selectedLanguage = _matchChoice(
        nextSelectedLanguage,
        _languages,
        _firstOrEmpty(_languages),
      );
      textDirection = nextTextDirection;
      dateFormat = _matchChoice(
        nextDateFormat,
        _dateFormats,
        _firstOrEmpty(_dateFormats),
      );
      timeFormat = nextTimeFormat;
      timezone = _matchChoice(
        nextTimezone,
        _timezones,
        _firstOrEmpty(_timezones),
      );
      units = nextUnits;
      lat = nextLat;
      lng = nextLng;
      zoom = nextZoom;

      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);
      _zoomController.text = zoom.toString();

      _loadedSnapshot ??= _defaultsSnapshot();
      if (nextSnapshot != null) {
        _loadedSnapshot = nextSnapshot;
      }
    });

    await _syncGlobalSettings();
  }

  Future<bool> _saveLocalization({bool showSuccess = true}) async {
    if (!_hasLocalizationSettingsEndpoint) {
      if (!_apiUnavailableShown && mounted) {
        _apiUnavailableShown = true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('API not available yet')));
      }
      return false;
    }

    if (_saving) return false;
    final now = DateTime.now();
    final last = _lastSaveAt;
    if (last != null && now.difference(last).inMilliseconds < 800) {
      return false;
    }
    _lastSaveAt = now;

    _saveToken?.cancel('Retry localization save');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return false;
    setState(() => _saving = true);

    final currentLat = double.tryParse(_latController.text) ?? lat;
    final currentLng = double.tryParse(_lngController.text) ?? lng;
    final currentZoom = int.tryParse(_zoomController.text) ?? zoom;

    // Use exact keys and string types as expected by the backend
    final payload = <String, dynamic>{
      'language': selectedLanguage,
      'dateFormat': dateFormat,
      'use24Hour': timeFormat == '24-hour',
      'theme': (themeController.themeMode.value == ThemeMode.dark) ? 'DARK' : 'LIGHT',
      'layoutDirection': textDirection,
      'mapZoom': currentZoom.toString(),
      'timezoneOffset': timezone,
      'units': units,
      'defaultLat': currentLat.toStringAsFixed(6),
      'defaultLon': currentLng.toStringAsFixed(6),
    };

    try {
      final res = await _superRepoOrCreate().updateLocalizationSettings(
        payload,
        cancelToken: token,
      );
      if (!mounted) return false;

      return res.when(
        success: (_) async {
          setState(() {
            _saving = false;
            _saveErrorShown = false;
            lat = currentLat;
            lng = currentLng;
            zoom = currentZoom;
            _loadedSnapshot = _captureCurrentSnapshot();
          });
          if (showSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Localization settings saved successfully.')));
          }
          await _syncGlobalSettings();
          return true;
        },
        failure: (err) {
          setState(() => _saving = false);
          if (!_saveErrorShown) {
            _saveErrorShown = true;
            final message =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to save localization settings.'
                : (err is ApiException ? err.message : "Couldn't save localization settings.");
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message ?? "Couldn't save localization settings.")));
          }
          return false;
        },
      );
    } catch (_) {
      if (!mounted) return false;
      setState(() => _saving = false);
      if (!_saveErrorShown) {
        _saveErrorShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save localization settings.")),
        );
      }
      return false;
    }
  }

  void _resetPressed() {
    final snapshot = _loadedSnapshot ?? _defaultsSnapshot();
    setState(() => _applySnapshot(snapshot));
    _syncGlobalSettings();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    if (_loading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(hp),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                AppShimmer(width: 100, height: 36, radius: 8),
                SizedBox(width: 12),
                AppShimmer(width: 92, height: 36, radius: 8),
              ],
            ),
            const SizedBox(height: 16),
            const AppShimmer(width: 240, height: 24, radius: 8),
            const SizedBox(height: 8),
            const AppShimmer(width: double.infinity, height: 16, radius: 8),
            const SizedBox(height: 24),
            _buildLoadingShimmer(width),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(hp),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // TOP BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Localization",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
              OutlinedButton.icon(
                onPressed: (_saving || _loading) ? null : _resetPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Icons.refresh_outlined,
                  color: colorScheme.onSurface,
                ),
                label: Text(
                  "Reset",
                  style: GoogleFonts.roboto(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_saving || _loading || !_isDirty)
                    ? null
                    : () => _saveLocalization(showSuccess: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: colorScheme.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: SizedBox(
                  width: 18,
                  height: 18,
                  child: _saving
                      ? const AppShimmer(width: 18, height: 18, radius: 9)
                      : Icon(Icons.save_outlined, color: colorScheme.onPrimary),
                ),
                label: Text(
                  "Save",
                  style: GoogleFonts.roboto(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 8),

          // LIVE PREVIEW
          _buildSection(
            context: context,
            title: "Live Preview",
            trailing: Text(
              "Lang: $selectedLanguage • Dir: $textDirection • TZ: $timezone",
              style: GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.right,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _previewItem(
                        "Date",
                        getFormattedDate(),
                        width,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _previewItem(
                        "Time",
                        getFormattedTime(),
                        width,
                        colorScheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Map Center",
                              style: GoogleFonts.roboto(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                        3,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$lat, $lng",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: AdaptiveUtils
                                            .getSubtitleFontSize(width) -
                                        3,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Zoom $zoom",
                                  style: GoogleFonts.roboto(
                                    fontSize: AdaptiveUtils
                                            .getSubtitleFontSize(width) -
                                        3,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _previewItem(
                        "Timezone",
                        timezone.isEmpty ? "—" : "$timezone\nUnits: $units",
                        width,
                        colorScheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DEFAULT LANGUAGE
          _buildSection(
            context: context,
            title: "",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.translate_outlined,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Default Language",
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Primary language",
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _languageOptions.isEmpty ? null : _pickLanguage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _languageOptions.isEmpty
                                ? 'No language options'
                                : _languageLabel(selectedLanguage),
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 2,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TEXT DIRECTION
          _buildSection(
            context: context,
            title: "",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.format_textdirection_l_to_r,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Text Direction",
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "LTR / RTL",
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => textDirection = "LTR");
                            themeController.setTextDirection('LTR');
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: textDirection == "LTR"
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.format_textdirection_l_to_r,
                                  size: 16,
                                  color: textDirection == "LTR"
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "LTR",
                                  style: GoogleFonts.roboto(
                                    color: textDirection == "LTR"
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => textDirection = "RTL");
                            themeController.setTextDirection('RTL');
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: textDirection == "RTL"
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.format_textdirection_r_to_l,
                                  size: 16,
                                  color: textDirection == "RTL"
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "RTL",
                                  style: GoogleFonts.roboto(
                                    color: textDirection == "RTL"
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DATE FORMAT
          _buildSection(
            context: context,
            title: "",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Date Format",
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Display style",
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _dropdownValueOrNull(_dateFormats, dateFormat),
                  hint: Text(
                    _dateFormats.isEmpty
                        ? 'No date format options'
                        : 'Select date format',
                    style: GoogleFonts.roboto(),
                  ),
                  decoration: _dropdownDecoration(context),
                  items: _dateFormats
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: _dateFormats.isEmpty
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() => dateFormat = v);
                          }
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TIME FORMAT
          _buildSection(
            context: context,
            title: "",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.schedule_outlined,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Time Format",
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeFormat == "24-hour"
                                ? "24-hour clock"
                                : "12-hour clock",
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => timeFormat = "24-hour"),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: timeFormat == "24-hour"
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: timeFormat == "24-hour"
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "24-hour",
                                  style: GoogleFonts.roboto(
                                    color: timeFormat == "24-hour"
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => timeFormat = "12-hour"),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: timeFormat == "12-hour"
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: timeFormat == "12-hour"
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "12-hour",
                                  style: GoogleFonts.roboto(
                                    color: timeFormat == "12-hour"
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TIMEZONE
          _buildSection(
            context: context,
            title: "",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.public_outlined,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Timezone",
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "UTC offset",
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _dropdownValueOrNull(_timezones, timezone),
                  hint: Text(
                    _timezones.isEmpty
                        ? 'No timezone options'
                        : 'Select timezone',
                    style: GoogleFonts.roboto(),
                  ),
                  decoration: _dropdownDecoration(context),
                  items: _timezones
                      .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                      .toList(),
                  onChanged: _timezones.isEmpty
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() => timezone = v);
                          }
                        },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // UNITS
          _buildSection(
            context: context,
            title: "",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.straighten_outlined,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Units",
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Distance units",
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => units = "KM");
                            themeController.setUnits('KM');
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: units == "KM"
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.straighten,
                                  size: 16,
                                  color: units == "KM"
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "KM",
                                  style: GoogleFonts.roboto(
                                    color: units == "KM"
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => units = "MILES");
                            themeController.setUnits('MILES');
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: units == "MILES"
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.straighten,
                                  size: 16,
                                  color: units == "MILES"
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "MILES",
                                  style: GoogleFonts.roboto(
                                    color: units == "MILES"
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // THEME
          _buildSection(
            context: context,
            title: "",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.palette_outlined,
                        color: colorScheme.onSurface,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Theme",
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Light / Dark / System",
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeController.themeMode,
                  builder: (context, mode, _) {
                    final selected = switch (mode) {
                      ThemeMode.dark => 'dark',
                      ThemeMode.system => 'system',
                      _ => 'light',
                    };
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _setThemeMode('light'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selected == 'light'
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.light_mode_outlined,
                                      size: 16,
                                      color: selected == 'light'
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Light",
                                      style: GoogleFonts.roboto(
                                        color: selected == 'light'
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _setThemeMode('dark'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selected == 'dark'
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.dark_mode_outlined,
                                      size: 16,
                                      color: selected == 'dark'
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Dark",
                                      style: GoogleFonts.roboto(
                                        color: selected == 'dark'
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _setThemeMode('system'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selected == 'system'
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.settings_outlined,
                                      size: 16,
                                      color: selected == 'system'
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "System",
                                      style: GoogleFonts.roboto(
                                        color: selected == 'system'
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSection(
          context: context,
          title: "Map Focus Coordinates",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                context,
                "Latitude (N/S)",
                _latController,
                labelStyle: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Range: -90 to 90",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildInputField(
                context,
                "Longitude (E/W)",
                _lngController,
                labelStyle: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Range: -180 to 180",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildInputField(
                context,
                "Zoom Level",
                _zoomController,
                labelStyle: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Typical: 1 to 20",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSection(
          context: context,
          title: "Quick Location Presets",
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double gap = 12;
              final double cellWidth = (constraints.maxWidth - gap) / 2;
              const presets = [
                {'name': 'New Delhi', 'lat': 28.6139, 'lng': 77.2090},
                {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
                {'name': 'Bengaluru', 'lat': 12.9716, 'lng': 77.5946},
                {'name': 'Kolkata', 'lat': 22.5726, 'lng': 88.3639},
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: presets.map((preset) {
                  final name = preset['name'] as String;
                  final latVal = preset['lat'] as double;
                  final lngVal = preset['lng'] as double;
                  return SizedBox(
                    width: cellWidth,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${latVal.toStringAsFixed(4)}, ${lngVal.toStringAsFixed(4)}',
                            style: GoogleFonts.roboto(
                              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer(double width) {
    return Column(
      children: [
        _buildShimmerCard(width: width, titleWidth: 180, fields: 3),
        const SizedBox(height: 24),
        _buildShimmerCard(width: width, titleWidth: 200, fields: 2),
        const SizedBox(height: 24),
        _buildShimmerCard(width: width, titleWidth: 170, fields: 2),
        const SizedBox(height: 24),
        _buildShimmerCard(width: width, titleWidth: 130, fields: 3),
      ],
    );
  }

  Widget _buildShimmerCard({
    required double width,
    required double titleWidth,
    required int fields,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double labelWidth = (width * 0.24).clamp(90, 180).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(width: titleWidth, height: 24, radius: 8),
          const SizedBox(height: 16),
          for (int i = 0; i < fields; i++) ...[
            AppShimmer(width: labelWidth, height: 12, radius: 8),
            const SizedBox(height: 8),
            const AppShimmer(width: double.infinity, height: 44, radius: 12),
            if (i != fields - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty || trailing != null)
            if (trailing == null)
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailing,
                    ),
                  ),
                ],
              ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
          if (child != null) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }

  Widget _previewItem(
    String label,
    String value,
    double width,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    TextStyle? labelStyle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelStyle ??
              GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocalizationSnapshot {
  final String selectedLanguage;
  final String textDirection;
  final String dateFormat;
  final String timeFormat;
  final String timezone;
  final String units;
  final double lat;
  final double lng;
  final int zoom;

  const _LocalizationSnapshot({
    required this.selectedLanguage,
    required this.textDirection,
    required this.dateFormat,
    required this.timeFormat,
    required this.timezone,
    required this.units,
    required this.lat,
    required this.lng,
    required this.zoom,
  });
}
