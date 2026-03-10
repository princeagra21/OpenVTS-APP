import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_localization_settings.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_localization_repository.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocalizationSettingsScreen extends StatelessWidget {
  const LocalizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: 'FLEET STACK',
      subtitle: 'Localization',
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
  // FleetStack-API-Reference.md + Postman confirmed endpoints:
  // - GET /languages
  // - GET /timezones
  // - GET /dateformats
  // - GET /admin/localization
  // - PATCH /admin/localization
  // PATCH keys used in this screen payload:
  // language, dateFormat, use24Hour, timezoneOffset, units,
  // layoutDirection, defaultLat, defaultLon, mapZoom

  String selectedLanguage = '';
  String textDirection = '';
  String dateFormat = '';
  String timeFormat = '';
  String selectedTimezoneOffset = '';
  String units = '';
  double? lat;
  double? lng;
  int? zoom;

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  final DateTime previewDate = DateTime(2025, 12, 7, 15, 28);
  final List<String> months = const [
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

  List<ReferenceOption> _languages = const [];
  List<ReferenceOption> _dateFormats = const [];
  List<TimezoneOption> _timezones = const [];

  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  DateTime? _lastSaveAt;

  CancelToken? _loadToken;
  CancelToken? _saveToken;

  ApiClient? _apiClient;
  CommonRepository? _commonRepo;
  AdminLocalizationRepository? _repo;

  _LocalizationSnapshot? _loadedSnapshot;

  @override
  void initState() {
    super.initState();
    final snapshot = _emptySnapshot();
    _loadedSnapshot = snapshot;
    _applySnapshot(snapshot);
    _loadLocalizationData();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Localization screen disposed');
    _saveToken?.cancel('Localization screen disposed');
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  ApiClient _apiClientOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _apiClient!;
  }

  CommonRepository _commonRepoOrCreate() {
    _commonRepo ??= CommonRepository(api: _apiClientOrCreate());
    return _commonRepo!;
  }

  AdminLocalizationRepository _repoOrCreate() {
    _repo ??= AdminLocalizationRepository(api: _apiClientOrCreate());
    return _repo!;
  }

  _LocalizationSnapshot _emptySnapshot() {
    return const _LocalizationSnapshot(
      selectedLanguage: '',
      textDirection: '',
      dateFormat: '',
      timeFormat: '',
      selectedTimezoneOffset: '',
      units: '',
      lat: null,
      lng: null,
      zoom: null,
    );
  }

  _LocalizationSnapshot _captureCurrentSnapshot() {
    return _LocalizationSnapshot(
      selectedLanguage: selectedLanguage,
      textDirection: textDirection,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      selectedTimezoneOffset: selectedTimezoneOffset,
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
    selectedTimezoneOffset = snapshot.selectedTimezoneOffset;
    units = snapshot.units;
    lat = snapshot.lat;
    lng = snapshot.lng;
    zoom = snapshot.zoom;

    _latController.text = snapshot.lat == null
        ? ''
        : snapshot.lat!.toStringAsFixed(4);
    _lngController.text = snapshot.lng == null
        ? ''
        : snapshot.lng!.toStringAsFixed(4);
  }

  String _safeDisplay(String value) {
    final v = value.trim();
    return v.isEmpty ? '—' : v;
  }

  bool _isCancelledError(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSaveErrorOnce(String message) {
    if (_saveErrorShown || !mounted) return;
    _saveErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _normalizeDirection(String raw, String fallback) {
    final v = raw.trim().toUpperCase();
    if (v == 'LTR') return 'LTR';
    if (v == 'RTL') return 'RTL';
    return fallback;
  }

  String _normalizeUnits(String raw, String fallback) {
    final v = raw.trim().toUpperCase();
    if (v == 'KM' || v == 'KMS' || v == 'KILOMETERS') return 'KM';
    if (v == 'MILE' || v == 'MILES' || v == 'MI') return 'MILES';
    return fallback;
  }

  String _timeFormatFromSettings(
    AdminLocalizationSettings settings,
    String fallback,
  ) {
    if (settings.use24Hour != null) {
      return settings.use24Hour! ? '24-hour' : '12-hour';
    }

    final tf = settings.timeFormat.toLowerCase();
    if (tf.contains('24')) return '24-hour';
    if (tf.contains('12')) return '12-hour';
    return fallback;
  }

  String _pickReferenceValue(
    String incoming,
    List<ReferenceOption> options,
    String fallback,
  ) {
    final inTrim = incoming.trim();
    if (inTrim.isEmpty) return fallback;
    for (final option in options) {
      if (option.value.toLowerCase() == inTrim.toLowerCase()) {
        return option.value;
      }
    }
    return fallback;
  }

  String _pickTimezoneValue(
    String incoming,
    List<TimezoneOption> options,
    String fallback,
  ) {
    final inTrim = incoming.trim();
    if (inTrim.isEmpty) return fallback;
    for (final option in options) {
      if (option.value.toLowerCase() == inTrim.toLowerCase()) {
        return option.value;
      }
    }
    return fallback;
  }

  List<ReferenceOption> _dedupeReferenceOptions(List<ReferenceOption> options) {
    final out = <ReferenceOption>[];
    final seen = <String>{};

    for (final item in options) {
      final value = item.value.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(
        ReferenceOption(
          value: value,
          label: item.label.trim().isEmpty ? value : item.label.trim(),
        ),
      );
    }

    return out;
  }

  List<TimezoneOption> _dedupeTimezoneOptions(List<TimezoneOption> options) {
    final out = <TimezoneOption>[];
    final seen = <String>{};

    for (final item in options) {
      final value = item.value.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(
        TimezoneOption(
          value: value,
          label: item.label.trim().isEmpty ? value : item.label.trim(),
        ),
      );
    }

    return out;
  }

  List<ReferenceOption> _ensureReferenceOption(
    List<ReferenceOption> options,
    String value,
  ) {
    final v = value.trim();
    if (v.isEmpty) return options;
    final has = options.any((o) => o.value.toLowerCase() == v.toLowerCase());
    if (has) return options;
    return [...options, ReferenceOption(value: v, label: v)];
  }

  List<TimezoneOption> _ensureTimezoneOption(
    List<TimezoneOption> options,
    String value,
  ) {
    final v = value.trim();
    if (v.isEmpty) return options;
    final has = options.any((o) => o.value.toLowerCase() == v.toLowerCase());
    if (has) return options;
    return [...options, TimezoneOption(value: v, label: v)];
  }

  String? _selectedReferenceValue(
    List<ReferenceOption> options,
    String current,
  ) {
    final c = current.trim();
    if (c.isEmpty) return null;
    final has = options.any((o) => o.value.toLowerCase() == c.toLowerCase());
    return has ? c : null;
  }

  String? _selectedTimezoneValue(List<TimezoneOption> options, String current) {
    final c = current.trim();
    if (c.isEmpty) return null;
    final has = options.any((o) => o.value.toLowerCase() == c.toLowerCase());
    return has ? c : null;
  }

  String _formatDatePreview() {
    if (dateFormat.trim().isEmpty) return '—';

    final day = previewDate.day.toString().padLeft(2, '0');
    final month = previewDate.month.toString().padLeft(2, '0');
    final year = previewDate.year.toString();
    final monthName = months[previewDate.month];
    final normalized = dateFormat.trim().toUpperCase();

    if (normalized == 'DD MMM YYYY' || normalized == 'DD MMM YYYY') {
      return '$day $monthName $year';
    }
    if (normalized == 'MM/DD/YYYY') {
      return '$month/$day/$year';
    }
    if (normalized == 'YYYY-MM-DD') {
      return '$year-$month-$day';
    }

    return '$day $monthName $year';
  }

  String _formatTimePreview() {
    if (timeFormat != '24-hour' && timeFormat != '12-hour') {
      return '—';
    }

    final minute = previewDate.minute.toString().padLeft(2, '0');
    if (timeFormat == '24-hour') {
      return '${previewDate.hour.toString().padLeft(2, '0')}:$minute';
    }

    final hour = previewDate.hour % 12 == 0 ? 12 : previewDate.hour % 12;
    final ampm = previewDate.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  String _formatMapCenterPreview() {
    if (lat == null || lng == null) return '—';
    return '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}';
  }

  String _formatZoomPreview() {
    if (zoom == null) return '—';
    return '$zoom';
  }

  Future<void> _loadLocalizationData() async {
    _loadToken?.cancel('Reload localization');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    var nextLanguages = List<ReferenceOption>.from(_languages);
    var nextDateFormats = List<ReferenceOption>.from(_dateFormats);
    var nextTimezones = List<TimezoneOption>.from(_timezones);
    var nextSnapshot = _loadedSnapshot ?? _emptySnapshot();
    var hadFailure = false;

    try {
      final commonRepo = _commonRepoOrCreate();

      final languagesRes = await commonRepo.getLanguages(cancelToken: token);
      if (!mounted) return;
      languagesRes.when(
        success: (items) {
          nextLanguages = _dedupeReferenceOptions(items);
        },
        failure: (err) {
          if (!_isCancelledError(err)) {
            hadFailure = true;
            final message =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to load language options.'
                : "Couldn't load language options.";
            _showLoadErrorOnce(message);
          }
        },
      );

      final dateFormatsRes = await commonRepo.getDateFormats(
        cancelToken: token,
      );
      if (!mounted) return;
      dateFormatsRes.when(
        success: (items) {
          nextDateFormats = _dedupeReferenceOptions(items);
        },
        failure: (err) {
          if (!_isCancelledError(err)) {
            hadFailure = true;
            final message =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to load date format options.'
                : "Couldn't load date format options.";
            _showLoadErrorOnce(message);
          }
        },
      );

      final timezonesRes = await commonRepo.getTimezones(cancelToken: token);
      if (!mounted) return;
      timezonesRes.when(
        success: (items) {
          nextTimezones = _dedupeTimezoneOptions(items);
        },
        failure: (err) {
          if (!_isCancelledError(err)) {
            hadFailure = true;
            final message =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to load timezone options.'
                : "Couldn't load timezone options.";
            _showLoadErrorOnce(message);
          }
        },
      );

      final settingsRes = await _repoOrCreate().getLocalization(
        cancelToken: token,
      );
      if (!mounted) return;

      settingsRes.when(
        success: (settings) {
          nextLanguages = _ensureReferenceOption(
            nextLanguages,
            settings.languageCode,
          );
          nextDateFormats = _ensureReferenceOption(
            nextDateFormats,
            settings.dateFormat,
          );
          nextTimezones = _ensureTimezoneOption(
            nextTimezones,
            settings.timezone,
          );

          final normalizedDirection = _normalizeDirection(
            settings.direction,
            nextSnapshot.textDirection,
          );

          final normalizedUnits = _normalizeUnits(
            settings.units,
            nextSnapshot.units,
          );

          var normalizedZoom = nextSnapshot.zoom;
          if (settings.mapZoom != null &&
              settings.mapZoom! >= 1 &&
              settings.mapZoom! <= 20) {
            normalizedZoom = settings.mapZoom;
          }

          nextSnapshot = _LocalizationSnapshot(
            selectedLanguage: _pickReferenceValue(
              settings.languageCode,
              nextLanguages,
              nextSnapshot.selectedLanguage,
            ),
            textDirection: normalizedDirection,
            dateFormat: _pickReferenceValue(
              settings.dateFormat,
              nextDateFormats,
              nextSnapshot.dateFormat,
            ),
            timeFormat: _timeFormatFromSettings(
              settings,
              nextSnapshot.timeFormat,
            ),
            selectedTimezoneOffset: _pickTimezoneValue(
              settings.timezone,
              nextTimezones,
              nextSnapshot.selectedTimezoneOffset,
            ),
            units: normalizedUnits,
            lat: settings.mapLat ?? nextSnapshot.lat,
            lng: settings.mapLng ?? nextSnapshot.lng,
            zoom: normalizedZoom,
          );
        },
        failure: (err) {
          if (!_isCancelledError(err)) {
            hadFailure = true;
            final message =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to load localization settings.'
                : "Couldn't load localization settings.";
            _showLoadErrorOnce(message);
          }
        },
      );
    } catch (_) {
      hadFailure = true;
      _showLoadErrorOnce("Couldn't load localization settings.");
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _languages = nextLanguages;
      _dateFormats = nextDateFormats;
      _timezones = nextTimezones;
      _loadedSnapshot = nextSnapshot;
      _applySnapshot(nextSnapshot);
      if (!hadFailure) {
        _loadErrorShown = false;
      }
    });
  }

  Future<void> _saveLocalization() async {
    if (_saving) return;

    final now = DateTime.now();
    if (_lastSaveAt != null &&
        now.difference(_lastSaveAt!).inMilliseconds < 800) {
      return;
    }
    _lastSaveAt = now;

    _saveToken?.cancel('Retry save localization');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{};
    if (selectedLanguage.trim().isNotEmpty) {
      payload['language'] = selectedLanguage.trim();
    }
    if (dateFormat.trim().isNotEmpty) {
      payload['dateFormat'] = dateFormat.trim();
    }
    if (timeFormat.trim().isNotEmpty) {
      payload['use24Hour'] = timeFormat == '24-hour';
    }
    if (selectedTimezoneOffset.trim().isNotEmpty) {
      payload['timezoneOffset'] = selectedTimezoneOffset.trim();
    }
    if (units.trim().isNotEmpty) {
      payload['units'] = units.trim();
    }
    if (textDirection.trim().isNotEmpty) {
      payload['layoutDirection'] = textDirection.trim();
    }
    if (lat != null) {
      payload['defaultLat'] = lat;
    }
    if (lng != null) {
      payload['defaultLon'] = lng;
    }
    if (zoom != null) {
      payload['mapZoom'] = zoom;
    }

    try {
      final result = await _repoOrCreate().updateLocalization(
        payload,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          setState(() {
            _saving = false;
            _saveErrorShown = false;
            _loadedSnapshot = _captureCurrentSnapshot();
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved')));
        },
        failure: (err) {
          setState(() => _saving = false);
          if (!_isCancelledError(err)) {
            final message =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to save localization settings.'
                : "Couldn't save localization settings.";
            _showSaveErrorOnce(message);
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSaveErrorOnce("Couldn't save localization settings.");
    }
  }

  void _onReset() {
    final snapshot = _loadedSnapshot ?? _emptySnapshot();
    setState(() {
      _applySnapshot(snapshot);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

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
          Text(
            'Localization Settings',
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure language, timezone, date formats, and map focus for your application.',
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: 'Live Preview',
            child: _loading
                ? _buildLivePreviewShimmer(width)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lang: ${_safeDisplay(selectedLanguage)} • Dir: ${_safeDisplay(textDirection)} • TZ: ${_safeDisplay(selectedTimezoneOffset)}',
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
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
                              'Date',
                              _formatDatePreview(),
                              width,
                              colorScheme,
                            ),
                          ),
                          Expanded(
                            child: _previewItem(
                              'Time',
                              _formatTimePreview(),
                              width,
                              colorScheme,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _previewItem(
                                  'Map Center',
                                  _formatMapCenterPreview(),
                                  width,
                                  colorScheme,
                                ),
                                const SizedBox(height: 6),
                                _previewItem(
                                  'Zoom',
                                  _formatZoomPreview(),
                                  width,
                                  colorScheme,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: 'Default Language',
            subtitle: 'Primary language',
            child: _loading
                ? const AppShimmer(
                    width: double.infinity,
                    height: 46,
                    radius: 16,
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedReferenceValue(
                      _languages,
                      selectedLanguage,
                    ),
                    decoration: _dropdownDecoration(context),
                    hint: Text(
                      '—',
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                      ),
                    ),
                    items: _languages
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.value,
                            child: Text(
                              e.label,
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (_saving)
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => selectedLanguage = v);
                          },
                  ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: 'Text Direction',
            child: _loading
                ? const AppShimmer(width: 180, height: 32, radius: 16)
                : Row(
                    children: [
                      ChoiceChip(
                        label: const Text('LTR'),
                        selected: textDirection == 'LTR',
                        selectedColor: colorScheme.primary,
                        labelStyle: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          color: textDirection == 'LTR'
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => textDirection = 'LTR'),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('RTL'),
                        selected: textDirection == 'RTL',
                        selectedColor: colorScheme.primary,
                        labelStyle: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          color: textDirection == 'RTL'
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => textDirection = 'RTL'),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: 'Date Format',
            subtitle: 'Display style',
            child: _loading
                ? const AppShimmer(
                    width: double.infinity,
                    height: 46,
                    radius: 16,
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedReferenceValue(_dateFormats, dateFormat),
                    decoration: _dropdownDecoration(context),
                    hint: Text(
                      '—',
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                      ),
                    ),
                    items: _dateFormats
                        .map(
                          (f) => DropdownMenuItem<String>(
                            value: f.value,
                            child: Text(
                              f.label,
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (_saving)
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => dateFormat = v);
                          },
                  ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: 'Time Format',
            child: _loading
                ? const AppShimmer(width: 220, height: 32, radius: 16)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('24-hour clock'),
                            selected: timeFormat == '24-hour',
                            selectedColor: colorScheme.primary,
                            labelStyle: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              color: timeFormat == '24-hour'
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                            onSelected: _saving
                                ? null
                                : (_) => setState(() => timeFormat = '24-hour'),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('12-hour clock'),
                            selected: timeFormat == '12-hour',
                            selectedColor: colorScheme.primary,
                            labelStyle: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              color: timeFormat == '12-hour'
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                            onSelected: _saving
                                ? null
                                : (_) => setState(() => timeFormat = '12-hour'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Example: ${_formatTimePreview()}',
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: 'Timezone',
            child: _loading
                ? const AppShimmer(
                    width: double.infinity,
                    height: 46,
                    radius: 16,
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedTimezoneValue(
                      _timezones,
                      selectedTimezoneOffset,
                    ),
                    decoration: _dropdownDecoration(context),
                    hint: Text(
                      '—',
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                      ),
                    ),
                    items: _timezones
                        .map(
                          (tz) => DropdownMenuItem<String>(
                            value: tz.value,
                            child: Text(
                              tz.label,
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => selectedTimezoneOffset = v);
                          },
                  ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: 'Units',
            child: _loading
                ? const AppShimmer(width: 180, height: 32, radius: 16)
                : Row(
                    children: [
                      ChoiceChip(
                        label: const Text('KM'),
                        selected: units == 'KM',
                        selectedColor: colorScheme.primary,
                        labelStyle: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          color: units == 'KM'
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => units = 'KM'),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('MILES'),
                        selected: units == 'MILES',
                        selectedColor: colorScheme.primary,
                        labelStyle: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          color: units == 'MILES'
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => units = 'MILES'),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            title: 'Map Focus',
            child: _loading
                ? _buildMapFocusShimmer(width)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              context,
                              'LATITUDE',
                              _latController,
                              (v) {
                                final parsed = double.tryParse(v.trim());
                                if (v.trim().isNotEmpty && parsed == null) {
                                  return;
                                }
                                setState(() => lat = parsed);
                              },
                            ),
                          ),
                          SizedBox(
                            width:
                                AdaptiveUtils.getLeftSectionSpacing(
                                  width,
                                ).toDouble() *
                                2,
                          ),
                          Expanded(
                            child: _buildInputField(
                              context,
                              'LONGITUDE',
                              _lngController,
                              (v) {
                                final parsed = double.tryParse(v.trim());
                                if (v.trim().isNotEmpty && parsed == null) {
                                  return;
                                }
                                setState(() => lng = parsed);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ZOOM LEVEL',
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      Slider(
                        value: (zoom ?? 10).toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        activeColor: colorScheme.primary,
                        label: _formatZoomPreview(),
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => zoom = v.toInt()),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: (_saving || _loading) ? null : _onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Icons.refresh_outlined,
                  color: colorScheme.onPrimary,
                  size: AdaptiveUtils.getIconSize(width),
                ),
                label: Text(
                  'Reset',
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_saving || _loading) ? null : _saveLocalization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _saving
                    ? const AppShimmer(width: 16, height: 16, radius: 4)
                    : Icon(
                        Icons.save_outlined,
                        color: colorScheme.onPrimary,
                        size: AdaptiveUtils.getIconSize(width),
                      ),
                label: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
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
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
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
          _safeDisplay(value),
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
    final double width = MediaQuery.of(context).size.width;

    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: AdaptiveUtils.isVerySmallScreen(width) ? 10 : 12,
      ),
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
    TextEditingController controller,
    void Function(String) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: !_saving,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: '—',
            hintStyle: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
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

  Widget _buildLivePreviewShimmer(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppShimmer(width: 290, height: 14, radius: 8),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: AppShimmer(width: double.infinity, height: 12, radius: 8),
            ),
            SizedBox(width: 12),
            Expanded(
              child: AppShimmer(width: double.infinity, height: 12, radius: 8),
            ),
            SizedBox(width: 12),
            Expanded(
              child: AppShimmer(width: double.infinity, height: 12, radius: 8),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapFocusShimmer(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Expanded(
              child: AppShimmer(width: double.infinity, height: 44, radius: 16),
            ),
            SizedBox(width: 12),
            Expanded(
              child: AppShimmer(width: double.infinity, height: 44, radius: 16),
            ),
          ],
        ),
        SizedBox(height: 24),
        AppShimmer(width: 130, height: 12, radius: 8),
        SizedBox(height: 8),
        AppShimmer(width: double.infinity, height: 18, radius: 8),
      ],
    );
  }
}

class _LocalizationSnapshot {
  final String selectedLanguage;
  final String textDirection;
  final String dateFormat;
  final String timeFormat;
  final String selectedTimezoneOffset;
  final String units;
  final double? lat;
  final double? lng;
  final int? zoom;

  const _LocalizationSnapshot({
    required this.selectedLanguage,
    required this.textDirection,
    required this.dateFormat,
    required this.timeFormat,
    required this.selectedTimezoneOffset,
    required this.units,
    required this.lat,
    required this.lng,
    required this.zoom,
  });
}
