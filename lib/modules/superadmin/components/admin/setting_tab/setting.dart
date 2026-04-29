// components/admin/admin_settings_tab.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_settings.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/main.dart' show themeController;
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSettingsTab extends StatefulWidget {
  final String adminId;

  const AdminSettingsTab({super.key, required this.adminId});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  // Selected values (fallback-first).
  String? _selectedTheme =
      'system'; // light|dark|system (system is client-mapped)
  String? _selectedUnit = 'KM';
  String? _selectedLanguage;
  String? _selectedDateFormat;
  String? _selectedTimeFormat; // 12h|24h
  String? _selectedTimezone;
  String? _selectedFirstDay;
  String? _selectedDirection = 'LTR';

  // Options (start with stable hardcoded values; replaced by API if available).
  List<ReferenceOption> _languageOptions = const [
    ReferenceOption(value: "en", label: "English"),
    ReferenceOption(value: "fr", label: "French"),
    ReferenceOption(value: "es", label: "Spanish"),
    ReferenceOption(value: "de", label: "German"),
  ];

  List<ReferenceOption> _dateFormatOptions = const [
    ReferenceOption(value: "dd/MM/yyyy", label: "DD/MM/YYYY"),
    ReferenceOption(value: "MM/dd/yyyy", label: "MM/DD/YYYY"),
    ReferenceOption(value: "yyyy-MM-dd", label: "YYYY-MM-DD"),
  ];

  // Postman does not list a /timeformats endpoint. Keep these stable.
  final List<ReferenceOption> _timeFormatOptions = const [
    ReferenceOption(value: "12h", label: "12-hour"),
    ReferenceOption(value: "24h", label: "24-hour"),
  ];

  List<TimezoneOption> _timezoneOptions = const [
    TimezoneOption(value: "GMT", label: "GMT"),
    TimezoneOption(value: "UTC", label: "UTC"),
    TimezoneOption(value: "EST", label: "EST"),
    TimezoneOption(value: "PST", label: "PST"),
  ];

  // No endpoint found for this; keep local-only.
  final List<ReferenceOption> _firstDayOptions = const [
    ReferenceOption(value: "monday", label: "Monday"),
    ReferenceOption(value: "tuesday", label: "Tuesday"),
    ReferenceOption(value: "wednesday", label: "Wednesday"),
    ReferenceOption(value: "thursday", label: "Thursday"),
    ReferenceOption(value: "friday", label: "Friday"),
    ReferenceOption(value: "saturday", label: "Saturday"),
    ReferenceOption(value: "sunday", label: "Sunday"),
  ];

  // UI-stability guards.
  bool _loading = false;
  bool _errorShown = false;
  bool _saveErrorShown = false;
  bool _saving = false;

  // Cancel on dispose.
  CancelToken? _loadToken;
  CancelToken? _saveToken;
  Timer? _saveDebounce;

  // Local deps (kept in-widget to avoid global state).
  ApiClient? _api;
  SuperadminRepository? _superadminRepo;
  CommonRepository? _commonRepo;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _saveToken?.cancel('dispose');
    _loadToken?.cancel('dispose');
    super.dispose();
  }

  Future<void> _ensureRepos() async {
    if (_api != null) return;
    final config = AppConfig.fromDartDefine();
    final tokenStorage = TokenStorage.defaultInstance();
    _api = ApiClient(config: config, tokenStorage: tokenStorage);
    _superadminRepo = SuperadminRepository(api: _api!);
    _commonRepo = CommonRepository(api: _api!);
  }

  String _prefsKey(String suffix) => 'admin_settings_${widget.adminId}_$suffix';

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLanguage ??= prefs.getString(_prefsKey('language'));
    _selectedDateFormat ??= prefs.getString(_prefsKey('date_format'));
    _selectedTimeFormat ??= prefs.getString(_prefsKey('time_format'));
    _selectedTimezone ??= prefs.getString(_prefsKey('timezone'));
    _selectedFirstDay ??= prefs.getString(_prefsKey('first_day'));
    _selectedDirection ??= prefs.getString(_prefsKey('direction'));
    _selectedTheme ??= prefs.getString(_prefsKey('theme')) ?? _selectedTheme;
    _selectedUnit ??= prefs.getString(_prefsKey('units')) ?? _selectedUnit;
  }

  Future<void> _persistLocalSettings({bool clearIfNull = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedLanguage != null) {
      await prefs.setString(_prefsKey('language'), _selectedLanguage!);
    } else if (clearIfNull) {
      await prefs.remove(_prefsKey('language'));
    }
    if (_selectedDateFormat != null) {
      await prefs.setString(_prefsKey('date_format'), _selectedDateFormat!);
    } else if (clearIfNull) {
      await prefs.remove(_prefsKey('date_format'));
    }
    if (_selectedTimeFormat != null) {
      await prefs.setString(_prefsKey('time_format'), _selectedTimeFormat!);
    } else if (clearIfNull) {
      await prefs.remove(_prefsKey('time_format'));
    }
    if (_selectedTimezone != null) {
      await prefs.setString(_prefsKey('timezone'), _selectedTimezone!);
    } else if (clearIfNull) {
      await prefs.remove(_prefsKey('timezone'));
    }
    if (_selectedFirstDay != null) {
      await prefs.setString(_prefsKey('first_day'), _selectedFirstDay!);
    } else if (clearIfNull) {
      await prefs.remove(_prefsKey('first_day'));
    }
    if (_selectedDirection != null) {
      await prefs.setString(_prefsKey('direction'), _selectedDirection!);
    } else if (clearIfNull) {
      await prefs.remove(_prefsKey('direction'));
    }
    if (_selectedTheme != null) {
      await prefs.setString(_prefsKey('theme'), _selectedTheme!);
    } else if (clearIfNull) {
      await prefs.remove(_prefsKey('theme'));
    }
    if (_selectedUnit != null) {
      await prefs.setString(_prefsKey('units'), _selectedUnit!);
    } else if (clearIfNull) {
      await prefs.remove(_prefsKey('units'));
    }
  }

  void _showSnackBarOnce(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _applyServerSettings(AdminSettings s, {bool clearIfEmpty = false}) {
    if (s.language.isNotEmpty) {
      _selectedLanguage = s.language;
    } else if (clearIfEmpty) {
      _selectedLanguage = null;
    }

    if (s.dateFormat.isNotEmpty) {
      _selectedDateFormat = s.dateFormat;
    } else if (clearIfEmpty) {
      _selectedDateFormat = null;
    }

    if (s.use24Hour != null) {
      _selectedTimeFormat = s.use24Hour! ? '24h' : '12h';
    } else if (clearIfEmpty) {
      _selectedTimeFormat = null;
    }

    if (s.timezoneOffset.isNotEmpty) {
      _selectedTimezone = s.timezoneOffset;
    } else if (clearIfEmpty) {
      _selectedTimezone = null;
    }

    if (s.units.isNotEmpty) {
      _selectedUnit = s.units;
    } else if (clearIfEmpty) {
      _selectedUnit = null;
    }

    final firstDayRaw =
        s.raw['firstDay'] ?? s.raw['first_day'] ?? s.raw['weekStart'];
    if (firstDayRaw != null && firstDayRaw.toString().trim().isNotEmpty) {
      _selectedFirstDay = firstDayRaw.toString();
    } else if (clearIfEmpty) {
      _selectedFirstDay = null;
    }

    final directionRaw =
        s.raw['direction'] ?? s.raw['textDirection'] ?? s.raw['dir'];
    if (directionRaw != null && directionRaw.toString().trim().isNotEmpty) {
      _selectedDirection = directionRaw.toString();
    } else if (clearIfEmpty) {
      _selectedDirection = null;
    }

    final t = s.themeRaw.trim().toLowerCase();
    if (t.isNotEmpty) {
      if (t.contains('dark')) _selectedTheme = 'dark';
      if (t.contains('light')) _selectedTheme = 'light';
      if (t.contains('system')) _selectedTheme = 'system';
    } else if (clearIfEmpty) {
      _selectedTheme = null;
    }
  }

  Future<void> _loadAll() async {
    await _ensureRepos();
    await _loadLocalSettings();

    if (!mounted) return;
    setState(() => _loading = true);

    _loadToken?.cancel('reload');
    _loadToken = CancelToken();

    try {
      // Reference data (public endpoints).
      final languagesRes = await _commonRepo!.getLanguages(
        cancelToken: _loadToken,
      );
      if (languagesRes.isSuccess && languagesRes.data!.isNotEmpty) {
        _languageOptions = languagesRes.data!;
      }

      final dateFormatsRes = await _commonRepo!.getDateFormats(
        cancelToken: _loadToken,
      );
      if (dateFormatsRes.isSuccess && dateFormatsRes.data!.isNotEmpty) {
        _dateFormatOptions = dateFormatsRes.data!;
      }

      final timezonesRes = await _commonRepo!.getTimezones(
        cancelToken: _loadToken,
      );
      if (timezonesRes.isSuccess && timezonesRes.data!.isNotEmpty) {
        _timezoneOptions = timezonesRes.data!;
      }

      // Admin settings (protected).
      final adminSettingsRes = await _superadminRepo!.getAdminSettings(
        widget.adminId,
        cancelToken: _loadToken,
      );

      if (adminSettingsRes.isSuccess) {
        _applyServerSettings(adminSettingsRes.data!);
        await _persistLocalSettings();
        await _syncAppSettings();
      } else if (!_errorShown) {
        _errorShown = true;
        _showSnackBarOnce("Couldn't load admin settings. Showing saved info.");
      }
    } catch (_) {
      if (!_errorShown) {
        _errorShown = true;
        _showSnackBarOnce("Couldn't load admin settings. Showing saved info.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetToServer() async {
    await _ensureRepos();
    if (!mounted) return;
    setState(() => _loading = true);

    _loadToken?.cancel('reset');
    _loadToken = CancelToken();

    try {
      final adminSettingsRes = await _superadminRepo!.getAdminSettings(
        widget.adminId,
        cancelToken: _loadToken,
      );

      if (adminSettingsRes.isSuccess) {
        _applyServerSettings(adminSettingsRes.data!, clearIfEmpty: true);
        await _persistLocalSettings(clearIfNull: true);
        await _syncAppSettings();
        if (mounted) {
          _showSnackBarOnce('Settings reset to saved values.');
        }
      } else if (!_errorShown) {
        _errorShown = true;
        _showSnackBarOnce("Couldn't reset settings.");
      }
    } catch (_) {
      if (!_errorShown) {
        _errorShown = true;
        _showSnackBarOnce("Couldn't reset settings.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _safeValue(String? selected, List<String> allowed) {
    if (selected == null) return null;
    return allowed.contains(selected) ? selected : null;
  }

  void _applyThemeToApp() {
    if (_selectedTheme == 'dark') {
      themeController.setThemeMode(ThemeMode.dark);
      return;
    }
    if (_selectedTheme == 'light') {
      themeController.setThemeMode(ThemeMode.light);
      return;
    }
    if (_selectedTheme == 'system') {
      themeController.setThemeMode(ThemeMode.system);
    }
  }

  Future<void> _syncAppSettings() async {
    _applyThemeToApp();
    if (_selectedDirection != null) {
      themeController.setTextDirection(_selectedDirection!);
    }
    if (_selectedUnit != null) {
      themeController.setUnits(_selectedUnit!);
    }
  }

  void _onAnySettingChanged() {
    _saveErrorShown = false;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _saveSettings);
  }

  Future<void> _saveSettings() async {
    if (_saving) return;
    await _ensureRepos();
    await _persistLocalSettings();

    if (!mounted) return;
    setState(() => _saving = true);

    _saveToken?.cancel('resave');
    _saveToken = CancelToken();

    final payload = <String, dynamic>{};
    if (_selectedLanguage != null && _selectedLanguage!.trim().isNotEmpty) {
      payload['language'] = _selectedLanguage;
    }
    if (_selectedDateFormat != null && _selectedDateFormat!.trim().isNotEmpty) {
      payload['dateFormat'] = _selectedDateFormat;
    }
    if (_selectedTimeFormat != null) {
      payload['use24Hour'] = _selectedTimeFormat == '24h';
    }
    if (_selectedTimezone != null && _selectedTimezone!.trim().isNotEmpty) {
      payload['timezoneOffset'] = _selectedTimezone;
    }
    if (_selectedUnit != null && _selectedUnit!.trim().isNotEmpty) {
      payload['units'] = _selectedUnit;
    }

    // Server expects LIGHT/DARK (Postman). "system" is client-only fallback.
    if (_selectedTheme == 'dark') payload['theme'] = 'DARK';
    if (_selectedTheme == 'light') payload['theme'] = 'LIGHT';

    if (payload.isEmpty) {
      if (mounted) {
        _showSnackBarOnce('Settings saved.');
        setState(() => _saving = false);
      }
      return;
    }

    try {
      final res = await _superadminRepo!.updateAdminSettings(
        widget.adminId,
        payload,
        cancelToken: _saveToken,
      );

      if (res.isSuccess) {
        _applyServerSettings(res.data!);
        await _persistLocalSettings();
        await _syncAppSettings();
        if (mounted) _showSnackBarOnce('Settings saved.');
      } else if (!_saveErrorShown) {
        _saveErrorShown = true;
        final err = res.error;
        if (err is ApiException &&
            (err.statusCode == 401 || err.statusCode == 403)) {
          _showSnackBarOnce("Not authorized to update settings.");
        } else {
          _showSnackBarOnce("Couldn't save settings.");
        }
      }
    } catch (_) {
      if (!_saveErrorShown) {
        _saveErrorShown = true;
        _showSnackBarOnce("Couldn't save settings.");
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSettingField({
    required IconData icon,
    required String label,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surfaceVariant,
          ),
          style: GoogleFonts.roboto(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          dropdownColor: colorScheme.surface,
          hint: Text(
            hint,
            style: GoogleFonts.roboto(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLanguagePicker({
    required String label,
    required String hint,
    required String? value,
    required List<ReferenceOption> options,
    required ValueChanged<String?> onSelected,
    bool showLabel = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    final selectedLabel = options
        .firstWhere(
          (o) => o.value == value,
          orElse: () => const ReferenceOption(value: '', label: ''),
        )
        .label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final chosen = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              backgroundColor: colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) {
                return SafeArea(
                  child: SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.7,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final opt = options[index];
                        return ListTile(
                          title: Text(
                            opt.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx, opt.value),
                        );
                      },
                    ),
                  ),
                );
              },
            );
            if (chosen == null) return;
            onSelected(chosen);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedLabel.isNotEmpty ? selectedLabel : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: selectedLabel.isNotEmpty
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required String value,
    required String label,
    required bool textOnTop,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    final bool isSelected = _selectedTheme == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedTheme = value);
          _applyThemeToApp();
          _onAnySettingChanged();
        },
        child: Column(
          children: [
            if (textOnTop)
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            Radio<String>(
              value: value,
              groupValue: _selectedTheme,
              activeColor: colorScheme.primary,
              onChanged: (v) {
                setState(() => _selectedTheme = v);
                _applyThemeToApp();
                _onAnySettingChanged();
              },
            ),
            if (!textOnTop)
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShimmer(
        width: double.infinity,
        height: 360,
        radius: 12,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;

    final languageItems = _languageOptions
        .map(
          (o) => DropdownMenuItem<String>(value: o.value, child: Text(o.label)),
        )
        .toList();

    final dateFormatItems = _dateFormatOptions
        .map(
          (o) => DropdownMenuItem<String>(value: o.value, child: Text(o.label)),
        )
        .toList();

    final timeFormatItems = _timeFormatOptions
        .map(
          (o) => DropdownMenuItem<String>(value: o.value, child: Text(o.label)),
        )
        .toList();

    final firstDayItems = _firstDayOptions
        .map(
          (o) => DropdownMenuItem<String>(value: o.value, child: Text(o.label)),
        )
        .toList();

    final languageValue = _safeValue(
      _selectedLanguage,
      _languageOptions.map((e) => e.value).toList(),
    );
    final dateFormatValue = _safeValue(
      _selectedDateFormat,
      _dateFormatOptions.map((e) => e.value).toList(),
    );
    final timeFormatValue = _safeValue(
      _selectedTimeFormat,
      _timeFormatOptions.map((e) => e.value).toList(),
    );
    final timezoneValue = _safeValue(
      _selectedTimezone,
      _timezoneOptions.map((e) => e.value).toList(),
    );
    final firstDayValue = _safeValue(
      _selectedFirstDay,
      _firstDayOptions.map((e) => e.value).toList(),
    );
    final themeLabel = (_selectedTheme ?? 'system').toUpperCase();
    final unitsLabel = (_selectedUnit ?? 'KM').toUpperCase();
    final dirLabel = (_selectedDirection ?? 'LTR').toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Main Admin Settings Container
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 400),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Admin Settings",
                          style: GoogleFonts.roboto(
                            fontSize: 18 *
                                (AdaptiveUtils.getTitleFontSize(
                                      MediaQuery.of(context).size.width,
                                    ) /
                                    14),
                            height: 24 / 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: AppShimmer(width: 12, height: 12, radius: 6),
                        ),
                      OutlinedButton(
                        onPressed: _loading ? null : _resetToServer,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          side: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _saving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Live Preview',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Theme: $themeLabel • Dir: $dirLabel • Units: $unitsLabel',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.onSurface.withOpacity(0.08),
                            ),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 12.0;
                              final cellWidth =
                                  (constraints.maxWidth - gap) / 2;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  SizedBox(
                                    width: cellWidth,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '30 March 2026',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: cellWidth,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Time',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '08:01',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'UTC +06:00',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.translate,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Language',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose language',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLanguagePicker(
                          label: 'Language',
                          hint: 'Select Language',
                          value: languageValue,
                          options: _languageOptions,
                          showLabel: false,
                          onSelected: (v) {
                            setState(() => _selectedLanguage = v);
                            _onAnySettingChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.format_textdirection_l_to_r,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Layout Direction',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Display direction',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
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
                                    setState(() => _selectedDirection = 'LTR');
                                    themeController.setTextDirection('LTR');
                                    _onAnySettingChanged();
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedDirection == 'LTR'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.format_textdirection_l_to_r,
                                          size: 16,
                                          color: _selectedDirection == 'LTR'
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'LTR',
                                          style: GoogleFonts.roboto(
                                            color: _selectedDirection == 'LTR'
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
                                    setState(() => _selectedDirection = 'RTL');
                                    themeController.setTextDirection('RTL');
                                    _onAnySettingChanged();
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedDirection == 'RTL'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.format_textdirection_r_to_l,
                                          size: 16,
                                          color: _selectedDirection == 'RTL'
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'RTL',
                                          style: GoogleFonts.roboto(
                                            color: _selectedDirection == 'RTL'
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.date_range,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date Format',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Display style',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLanguagePicker(
                          label: 'Date Format',
                          hint: 'Select Date Format',
                          value: dateFormatValue,
                          options: _dateFormatOptions,
                          showLabel: false,
                          onSelected: (v) {
                            setState(() => _selectedDateFormat = v);
                            _onAnySettingChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.access_time,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time Format',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '24-hour clock',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTimeFormat == '24h'
                                  ? '24-hour clock'
                                  : '12-hour clock',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            Switch(
                              value: _selectedTimeFormat == '24h',
                              onChanged: (v) {
                                setState(
                                  () => _selectedTimeFormat = v ? '24h' : '12h',
                                );
                                _onAnySettingChanged();
                              },
                              activeColor: colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Theme Selection Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.brightness_6,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Light / Dark / System',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
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
                                    setState(() => _selectedTheme = 'light');
                                    _applyThemeToApp();
                                    _onAnySettingChanged();
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedTheme == 'light'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Light',
                                      style: GoogleFonts.roboto(
                                        color: _selectedTheme == 'light'
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedTheme = 'dark');
                                    _applyThemeToApp();
                                    _onAnySettingChanged();
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedTheme == 'dark'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Dark',
                                      style: GoogleFonts.roboto(
                                        color: _selectedTheme == 'dark'
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedTheme = 'system');
                                    _applyThemeToApp();
                                    _onAnySettingChanged();
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedTheme == 'system'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'System',
                                      style: GoogleFonts.roboto(
                                        color: _selectedTheme == 'system'
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.public,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Timezone',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'UTC Offset',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLanguagePicker(
                          label: 'Timezone',
                          hint: 'Select Timezone',
                          showLabel: false,
                          value: timezoneValue,
                          options: _timezoneOptions
                              .map(
                                (o) => ReferenceOption(
                                  value: o.value,
                                  label: o.label,
                                ),
                              )
                              .toList(),
                          onSelected: (v) {
                            setState(() => _selectedTimezone = v);
                            _onAnySettingChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Units Selection Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.straighten,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Units',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Distance units',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
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
                                    setState(() => _selectedUnit = 'KM');
                                    themeController.setUnits('KM');
                                    _onAnySettingChanged();
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedUnit == 'KM'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'KM',
                                      style: GoogleFonts.roboto(
                                        color: _selectedUnit == 'KM'
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedUnit = 'MILES');
                                    themeController.setUnits('MILES');
                                    _onAnySettingChanged();
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedUnit == 'MILES'
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Miles',
                                      style: GoogleFonts.roboto(
                                        color: _selectedUnit == 'MILES'
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
