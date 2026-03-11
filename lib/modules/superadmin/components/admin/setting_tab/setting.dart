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
    _selectedTheme ??= prefs.getString(_prefsKey('theme')) ?? _selectedTheme;
    _selectedUnit ??= prefs.getString(_prefsKey('units')) ?? _selectedUnit;
  }

  Future<void> _persistLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedLanguage != null) {
      await prefs.setString(_prefsKey('language'), _selectedLanguage!);
    }
    if (_selectedDateFormat != null) {
      await prefs.setString(_prefsKey('date_format'), _selectedDateFormat!);
    }
    if (_selectedTimeFormat != null) {
      await prefs.setString(_prefsKey('time_format'), _selectedTimeFormat!);
    }
    if (_selectedTimezone != null) {
      await prefs.setString(_prefsKey('timezone'), _selectedTimezone!);
    }
    if (_selectedFirstDay != null) {
      await prefs.setString(_prefsKey('first_day'), _selectedFirstDay!);
    }
    if (_selectedTheme != null) {
      await prefs.setString(_prefsKey('theme'), _selectedTheme!);
    }
    if (_selectedUnit != null) {
      await prefs.setString(_prefsKey('units'), _selectedUnit!);
    }
  }

  void _showSnackBarOnce(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _applyServerSettings(AdminSettings s) {
    if (s.language.isNotEmpty) _selectedLanguage = s.language;
    if (s.dateFormat.isNotEmpty) _selectedDateFormat = s.dateFormat;
    if (s.use24Hour != null) _selectedTimeFormat = s.use24Hour! ? '24h' : '12h';
    if (s.timezoneOffset.isNotEmpty) _selectedTimezone = s.timezoneOffset;
    if (s.units.isNotEmpty) _selectedUnit = s.units;

    final t = s.themeRaw.trim().toLowerCase();
    if (t.isNotEmpty) {
      if (t.contains('dark')) _selectedTheme = 'dark';
      if (t.contains('light')) _selectedTheme = 'light';
      if (t.contains('system')) _selectedTheme = 'system';
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

  String? _safeValue(String? selected, List<String> allowed) {
    if (selected == null) return null;
    return allowed.contains(selected) ? selected : null;
  }

  void _applyThemeToApp() {
    // ThemeController supports only light/dark. For "system", map to current device brightness.
    if (_selectedTheme == 'dark') {
      themeController.setDarkMode(true);
      return;
    }
    if (_selectedTheme == 'light') {
      themeController.setDarkMode(false);
      return;
    }
    if (_selectedTheme == 'system') {
      final isDark =
          MediaQuery.of(context).platformBrightness == Brightness.dark;
      themeController.setDarkMode(isDark);
    }
  }

  void _onAnySettingChanged() {
    _saveErrorShown = false;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _saveSettings);
  }

  Future<void> _saveSettings() async {
    await _ensureRepos();
    await _persistLocalSettings();

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

    if (payload.isEmpty) return;

    try {
      final res = await _superadminRepo!.updateAdminSettings(
        widget.adminId,
        payload,
        cancelToken: _saveToken,
      );

      if (!res.isSuccess && !_saveErrorShown) {
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
              style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          dropdownColor: colorScheme.surface,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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

    final timezoneItems = _timezoneOptions
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
                      Icon(
                        Icons.settings,
                        size: 24,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Admin Settings",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: _loading
                            ? const AppShimmer(width: 12, height: 12, radius: 6)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSettingField(
                    icon: Icons.language,
                    label: "Language",
                    hint: "Select Language",
                    items: languageItems,
                    value: languageValue,
                    onChanged: (v) {
                      setState(() => _selectedLanguage = v);
                      _onAnySettingChanged();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    icon: Icons.date_range,
                    label: "Date Format",
                    hint: "Select Date Format",
                    items: dateFormatItems,
                    value: dateFormatValue,
                    onChanged: (v) {
                      setState(() => _selectedDateFormat = v);
                      _onAnySettingChanged();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    icon: Icons.access_time,
                    label: "Time Format",
                    hint: "Select Time Format",
                    items: timeFormatItems,
                    value: timeFormatValue,
                    onChanged: (v) {
                      setState(() => _selectedTimeFormat = v);
                      _onAnySettingChanged();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    icon: Icons.public,
                    label: "Time Zone",
                    hint: "Select Time Zone",
                    items: timezoneItems,
                    value: timezoneValue,
                    onChanged: (v) {
                      setState(() => _selectedTimezone = v);
                      _onAnySettingChanged();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSettingField(
                    icon: Icons.calendar_view_week,
                    label: "First Day of Week",
                    hint: "Select First Day",
                    items: firstDayItems,
                    value: firstDayValue,
                    onChanged: (v) {
                      setState(() => _selectedFirstDay = v);
                      _onAnySettingChanged();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Theme Selection Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.brightness_6,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Theme",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildThemeOption(
                      value: "light",
                      label: "Light",
                      textOnTop: true,
                    ),
                    _buildThemeOption(
                      value: "dark",
                      label: "Dark",
                      textOnTop: false,
                    ),
                    _buildThemeOption(
                      value: "system",
                      label: "System",
                      textOnTop: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Units Selection Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Units",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedUnit = 'KM');
                          _onAnySettingChanged();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Radio<String>(
                              value: "KM",
                              groupValue: _selectedUnit,
                              activeColor: colorScheme.primary,
                              onChanged: (v) {
                                setState(() => _selectedUnit = v);
                                _onAnySettingChanged();
                              },
                            ),
                            Text(
                              "KM",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _selectedUnit == 'KM'
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedUnit = 'MILES');
                          _onAnySettingChanged();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Radio<String>(
                              value: "MILES",
                              groupValue: _selectedUnit,
                              activeColor: colorScheme.primary,
                              onChanged: (v) {
                                setState(() => _selectedUnit = v);
                                _onAnySettingChanged();
                              },
                            ),
                            Text(
                              "MILES",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _selectedUnit == 'MILES'
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
