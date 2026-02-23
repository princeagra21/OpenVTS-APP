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

  List<String> _languages = const [];
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

  @override
  void initState() {
    super.initState();
    _loadedSnapshot = _defaultsSnapshot();
    _loadLocalizationData();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Localization disposed');
    _saveToken?.cancel('Localization disposed');
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

  String _firstOrEmpty(List<String> values) {
    if (values.isEmpty) return '';
    return values.first;
  }

  String? _dropdownValueOrNull(List<String> options, String current) {
    if (current.trim().isEmpty) return null;
    final has = options.any((e) => e.toLowerCase() == current.toLowerCase());
    return has ? current : null;
  }

  Future<void> _loadLocalizationData() async {
    _loadToken?.cancel('Reload localization');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

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
          final values = items.map((e) => e.value).toList();
          nextLanguages = _optionsOrFallback(values, _languages);
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
            nextLanguages = _ensureContains(
              nextLanguages,
              settings.languageCode,
            );
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
      _loadedSnapshot ??= _defaultsSnapshot();
      if (nextSnapshot != null) {
        _loadedSnapshot = nextSnapshot;
      }
    });
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

    final payload = <String, dynamic>{
      'language': selectedLanguage,
      'languageCode': selectedLanguage,
      'dateFormat': dateFormat,
      'use24Hour': timeFormat == '24-hour',
      'timeFormat': timeFormat == '24-hour' ? '24H' : '12H',
      'layoutDirection': textDirection,
      'direction': textDirection,
      'timezoneOffset': timezone,
      'timezone': timezone,
      'units': units,
      'distanceUnit': units,
      'defaultLat': lat.toStringAsFixed(6),
      'defaultLon': lng.toStringAsFixed(6),
      'defaultLng': lng.toStringAsFixed(6),
      'mapZoom': zoom.toString(),
    };

    try {
      final res = await _superRepoOrCreate().updateLocalizationSettings(
        payload,
        cancelToken: token,
      );
      if (!mounted) return false;

      return res.when(
        success: (_) {
          setState(() {
            _saving = false;
            _saveErrorShown = false;
            _loadedSnapshot = _captureCurrentSnapshot();
          });
          if (showSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Saved')));
          }
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
                : "Couldn't save localization settings.";
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
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
          // TOP BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: (_saving || _loading) ? null : _resetPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Icons.refresh_outlined,
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  "Reset",
                  style: GoogleFonts.inter(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_saving || _loading)
                    ? null
                    : () => _saveLocalization(showSuccess: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: SizedBox(
                  width: 18,
                  height: 18,
                  child: _saving
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        )
                      : Icon(Icons.save_outlined, color: colorScheme.onPrimary),
                ),
                label: Text(
                  "Save",
                  style: GoogleFonts.inter(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // TITLE
          Text(
            "Localization Settings",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configure language, timezone, date formats, and map focus for your application.",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 24),

          // LIVE PREVIEW
          _buildSection(
            context: context,
            title: "Live Preview",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lang: $selectedLanguage • Dir: $textDirection • TZ: $timezone",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
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
                    Expanded(
                      child: _previewItem(
                        "Time",
                        getFormattedTime(),
                        width,
                        colorScheme,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _previewItem(
                            "Map Center",
                            "$lat, $lng",
                            width,
                            colorScheme,
                          ),
                          _previewItem("Zoom", "$zoom", width, colorScheme),
                        ],
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
            title: "Default Language",
            subtitle: "Primary language",
            child: DropdownButtonFormField<String>(
              value: _dropdownValueOrNull(_languages, selectedLanguage),
              hint: Text(
                _languages.isEmpty ? 'No language options' : 'Select language',
                style: GoogleFonts.inter(),
              ),
              decoration: _dropdownDecoration(context),
              items: _languages
                  .map(
                    (lang) => DropdownMenuItem(value: lang, child: Text(lang)),
                  )
                  .toList(),
              onChanged: _languages.isEmpty
                  ? null
                  : (v) {
                      if (v != null) {
                        setState(() => selectedLanguage = v);
                      }
                    },
            ),
          ),

          const SizedBox(height: 24),

          // TEXT DIRECTION
          _buildSection(
            context: context,
            title: "Text Direction",
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("LTR"),
                  selected: textDirection == "LTR",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    color: textDirection == "LTR"
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  onSelected: (_) => setState(() => textDirection = "LTR"),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("RTL"),
                  selected: textDirection == "RTL",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    color: textDirection == "RTL"
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  onSelected: (_) => setState(() => textDirection = "RTL"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DATE FORMAT
          _buildSection(
            context: context,
            title: "Date Format",
            subtitle: "Display style",
            child: DropdownButtonFormField<String>(
              value: _dropdownValueOrNull(_dateFormats, dateFormat),
              hint: Text(
                _dateFormats.isEmpty
                    ? 'No date format options'
                    : 'Select date format',
                style: GoogleFonts.inter(),
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
          ),

          const SizedBox(height: 24),

          // TIME FORMAT
          _buildSection(
            context: context,
            title: "Time Format",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("24-hour clock"),
                      selected: timeFormat == "24-hour",
                      selectedColor: colorScheme.primary,
                      labelStyle: GoogleFonts.inter(
                        color: timeFormat == "24-hour"
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => timeFormat = "24-hour"),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text("12-hour clock"),
                      selected: timeFormat == "12-hour",
                      selectedColor: colorScheme.primary,
                      labelStyle: GoogleFonts.inter(
                        color: timeFormat == "12-hour"
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      onSelected: (_) => setState(() => timeFormat = "12-hour"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Example: ${getFormattedTime()}",
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TIMEZONE
          _buildSection(
            context: context,
            title: "Timezone",
            child: DropdownButtonFormField<String>(
              value: _dropdownValueOrNull(_timezones, timezone),
              hint: Text(
                _timezones.isEmpty ? 'No timezone options' : 'Select timezone',
                style: GoogleFonts.inter(),
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
          ),

          const SizedBox(height: 24),

          // UNITS
          _buildSection(
            context: context,
            title: "Units",
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("KM"),
                  selected: units == "KM",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    color: units == "KM"
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  onSelected: (_) => setState(() => units = "KM"),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("MILES"),
                  selected: units == "MILES",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    color: units == "MILES"
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  onSelected: (_) => setState(() => units = "MILES"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // MAP FOCUS
          _buildSection(
            context: context,
            title: "Map Focus",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        context,
                        "LATITUDE",
                        lat.toStringAsFixed(4),
                        (v) => lat = double.tryParse(v) ?? lat,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        context,
                        "LONGITUDE",
                        lng.toStringAsFixed(4),
                        (v) => lng = double.tryParse(v) ?? lng,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "ZOOM LEVEL",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                Slider(
                  value: zoom.toDouble(),
                  min: 1,
                  max: 22,
                  divisions: 21,
                  activeColor: colorScheme.primary,
                  label: zoom.toString(),
                  onChanged: (v) => setState(() => zoom = v.toInt()),
                ),
              ],
            ),
          ),
        ],
      ),
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
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: colorScheme.onSurface.withOpacity(0.8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
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
    String initial,
    void Function(String) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: initial)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: initial.length),
            ),
          onChanged: onChanged,
          style: GoogleFonts.inter(color: colorScheme.onSurface),
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
