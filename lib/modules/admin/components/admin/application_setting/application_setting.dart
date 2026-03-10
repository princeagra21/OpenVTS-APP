import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_app_preferences.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_app_preferences_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplicationSettingsScreen extends StatelessWidget {
  const ApplicationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: 'FLEET STACK',
      subtitle: 'Settings',
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const ApplicationHeader(), const SizedBox(height: 24)],
        ),
      ),
    );
  }
}

class ApplicationHeader extends StatefulWidget {
  const ApplicationHeader({super.key});

  @override
  State<ApplicationHeader> createState() => _ApplicationHeaderState();
}

class _ApplicationHeaderState extends State<ApplicationHeader> {
  // Endpoint mapping (FleetStack-API-Reference.md + Postman):
  // - GET /admin/config
  // - PATCH /admin/config
  // PATCH payload keys used by this screen:
  // allowDemoLogin, geocodingPrecision, backupDays, allowSignup, signupCredits

  bool? demoEnabled;
  String geocodingPrecision = '';
  String backupRetention = '';
  int? freeCredits;
  bool? signupAllowed;

  final TextEditingController _freeCreditsController = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _hasData = false;

  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  DateTime? _lastSaveAt;

  CancelToken? _loadToken;
  CancelToken? _saveToken;

  ApiClient? _apiClient;
  AdminAppPreferencesRepository? _repo;

  _ApplicationSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    final empty = _emptySnapshot();
    _snapshot = empty;
    _applySnapshot(empty);
    _loadPreferences();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Application settings disposed');
    _saveToken?.cancel('Application settings disposed');
    _freeCreditsController.dispose();
    super.dispose();
  }

  ApiClient _apiClientOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _apiClient!;
  }

  AdminAppPreferencesRepository _repoOrCreate() {
    _repo ??= AdminAppPreferencesRepository(api: _apiClientOrCreate());
    return _repo!;
  }

  _ApplicationSnapshot _emptySnapshot() {
    return const _ApplicationSnapshot(
      demoEnabled: null,
      geocodingPrecision: '',
      backupRetention: '',
      freeCredits: null,
      signupAllowed: null,
    );
  }

  _ApplicationSnapshot _captureCurrentSnapshot() {
    return _ApplicationSnapshot(
      demoEnabled: demoEnabled,
      geocodingPrecision: geocodingPrecision,
      backupRetention: backupRetention,
      freeCredits: freeCredits,
      signupAllowed: signupAllowed,
    );
  }

  void _applySnapshot(_ApplicationSnapshot snapshot) {
    demoEnabled = snapshot.demoEnabled;
    geocodingPrecision = snapshot.geocodingPrecision;
    backupRetention = snapshot.backupRetention;
    freeCredits = snapshot.freeCredits;
    signupAllowed = snapshot.signupAllowed;

    _freeCreditsController.text = snapshot.freeCredits?.toString() ?? '';
  }

  bool _isCancelled(Object err) {
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

  Future<void> _loadPreferences() async {
    _loadToken?.cancel('Reload app settings');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getAdminAppPreferences(
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (prefs) {
          final mapped = _ApplicationSnapshot(
            demoEnabled: prefs.allowDemoLogin,
            geocodingPrecision: prefs.geocodingPrecision == null
                ? ''
                : (prefs.geocodingPrecision! >= 3 ? '3 Digits' : '2 Digits'),
            backupRetention: prefs.backupRetentionLabel,
            freeCredits: prefs.signupCredits,
            signupAllowed: prefs.allowSignup,
          );

          final hasData = prefs.hasAnyValue;

          setState(() {
            _loading = false;
            _loadErrorShown = false;
            _hasData = hasData;
            _snapshot = hasData ? mapped : _emptySnapshot();
            _applySnapshot(_snapshot!);
          });
        },
        failure: (err) {
          setState(() {
            _loading = false;
            _hasData = false;
            _snapshot = _emptySnapshot();
            _applySnapshot(_snapshot!);
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load settings.'
              : "Couldn't load settings.";
          _showLoadErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasData = false;
        _snapshot = _emptySnapshot();
        _applySnapshot(_snapshot!);
      });
      _showLoadErrorOnce("Couldn't load settings.");
    }
  }

  Future<void> _savePreferences() async {
    if (_saving) return;

    final now = DateTime.now();
    final last = _lastSaveAt;
    if (last != null && now.difference(last).inMilliseconds < 800) {
      return;
    }
    _lastSaveAt = now;

    _saveToken?.cancel('Retry app settings save');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() => _saving = true);

    final payload = AdminAppPreferences(const <String, dynamic>{})
        .toPatchPayload(
          allowDemoLogin: demoEnabled,
          geocodingPrecision: geocodingPrecision == '3 Digits'
              ? 3
              : (geocodingPrecision == '2 Digits' ? 2 : null),
          backupRetention: backupRetention,
          allowSignup: signupAllowed,
          signupCredits: freeCredits,
        );

    if (payload.isEmpty) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSaveErrorOnce('No settings available to save.');
      return;
    }

    try {
      final res = await _repoOrCreate().updateAdminAppPreferences(
        payload,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          setState(() {
            _saving = false;
            _saveErrorShown = false;
            _snapshot = _captureCurrentSnapshot();
            _hasData = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved')));
        },
        failure: (err) {
          setState(() => _saving = false);
          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to update settings.'
              : "Couldn't save settings.";
          _showSaveErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSaveErrorOnce("Couldn't save settings.");
    }
  }

  void _resetPressed() {
    final snapshot = _snapshot ?? _emptySnapshot();
    setState(() => _applySnapshot(snapshot));
  }

  String _summaryDemoStatus() {
    if (demoEnabled == null) return '—';
    return demoEnabled! ? 'ON' : 'OFF';
  }

  String _summarySignupStatus() {
    if (signupAllowed == null) return '—';
    return signupAllowed! ? 'ALLOWED' : 'DISABLED';
  }

  String _summaryGeocoding() {
    final geo = geocodingPrecision.trim();
    if (geo.isEmpty) return '—';
    return geo;
  }

  String? _backupDropdownValue() {
    final value = backupRetention.trim();
    if (value.isEmpty) return null;
    const options = ['1 Month', '3 Months', '6 Months', '12 Months'];
    return options.contains(value) ? value : null;
  }

  bool get _canEdit => !_loading && !_saving && _hasData;

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
          const SizedBox(height: 16),

          Text(
            'Application Settings',
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure system-wide settings for your application.',
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width),
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            icon: Icons.settings_rounded,
            title: 'Current Configuration',
            child: _loading
                ? const AppShimmer(width: 340, height: 14, radius: 8)
                : Text(
                    'Demo: ${_summaryDemoStatus()} • Geocoding: ${_summaryGeocoding()} • Signup: ${_summarySignupStatus()}',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
          ),

          const SizedBox(height: 24),

          _buildToggleSection(
            context: context,
            icon: Icons.login_rounded,
            title: 'Demo Login',
            subtitle: _loading
                ? '—'
                : (demoEnabled == null
                      ? '—'
                      : (demoEnabled!
                            ? 'Demo login is enabled'
                            : 'Demo login is disabled')),
            value: demoEnabled ?? false,
            enabled: _canEdit,
            loading: _loading,
            onChanged: (v) => setState(() => demoEnabled = v),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            icon: Icons.location_on_rounded,
            title: 'Reverse Geocoding',
            child: _loading
                ? Row(
                    children: const [
                      AppShimmer(width: 120, height: 46, radius: 12),
                      SizedBox(width: 12),
                      AppShimmer(width: 140, height: 46, radius: 12),
                    ],
                  )
                : Row(
                    children: [
                      ChoiceChip(
                        label: const Text('2 Digits\nCity/Region'),
                        selected: geocodingPrecision == '2 Digits',
                        selectedColor: colorScheme.primary,
                        labelStyle: GoogleFonts.inter(
                          color: geocodingPrecision == '2 Digits'
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        onSelected: _canEdit
                            ? (_) => setState(
                                () => geocodingPrecision = '2 Digits',
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('3 Digits\nStreet Level'),
                        selected: geocodingPrecision == '3 Digits',
                        selectedColor: colorScheme.primary,
                        labelStyle: GoogleFonts.inter(
                          color: geocodingPrecision == '3 Digits'
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        onSelected: _canEdit
                            ? (_) => setState(
                                () => geocodingPrecision = '3 Digits',
                              )
                            : null,
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            icon: Icons.backup_rounded,
            title: 'Database Backup',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _loading
                    ? const AppShimmer(
                        width: double.infinity,
                        height: 44,
                        radius: 16,
                      )
                    : DropdownButtonFormField<String>(
                        value: _backupDropdownValue(),
                        hint: Text(
                          '—',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        decoration: _dropdownDecoration(context),
                        items:
                            const [
                                  '1 Month',
                                  '3 Months',
                                  '6 Months',
                                  '12 Months',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: _canEdit
                            ? (v) {
                                if (v == null) return;
                                setState(() => backupRetention = v);
                              }
                            : null,
                      ),
                const SizedBox(height: 12),
                Text(
                  _loading
                      ? '—'
                      : (_hasData
                            ? 'Backups will be retained for the selected period'
                            : '—'),
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            context: context,
            icon: Icons.person_add_rounded,
            title: 'Signup Configuration',
            child: _loading
                ? _buildSignupShimmer()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Allow New Signups',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: signupAllowed ?? false,
                              activeColor: colorScheme.onPrimary,
                              activeTrackColor: colorScheme.primary,
                              inactiveThumbColor: colorScheme.onPrimary,
                              inactiveTrackColor: colorScheme.primary
                                  .withOpacity(0.3),
                              onChanged: _canEdit
                                  ? (v) => setState(() => signupAllowed = v)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        signupAllowed == null
                            ? '—'
                            : (signupAllowed!
                                  ? 'New users can register'
                                  : 'New user registration is disabled'),
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Free Signup Credits',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _freeCreditsController,
                        keyboardType: TextInputType.number,
                        enabled: _canEdit,
                        onChanged: (v) {
                          final trimmed = v.trim();
                          if (trimmed.isEmpty) {
                            setState(() => freeCredits = null);
                            return;
                          }
                          final parsed = int.tryParse(trimmed);
                          if (parsed == null) return;
                          setState(() => freeCredits = parsed);
                        },
                        style: GoogleFonts.inter(color: colorScheme.onSurface),
                        decoration: _inputDecoration(
                          context,
                          hint: _hasData
                              ? 'Number of free credits awarded to new users upon signup'
                              : '—',
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

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
                  size: AdaptiveUtils.getIconSize(width),
                ),
                label: Text(
                  'Reset',
                  style: GoogleFonts.inter(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_saving || _loading || !_hasData)
                    ? null
                    : _savePreferences,
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

  Widget _buildSignupShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppShimmer(width: 150, height: 14, radius: 8),
            AppShimmer(width: 38, height: 20, radius: 10),
          ],
        ),
        SizedBox(height: 12),
        AppShimmer(width: 220, height: 14, radius: 8),
        SizedBox(height: 24),
        AppShimmer(width: 130, height: 14, radius: 8),
        SizedBox(height: 8),
        AppShimmer(width: double.infinity, height: 44, radius: 16),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
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
          Row(
            children: [
              Icon(
                icon,
                size: AdaptiveUtils.getTitleFontSize(width) + 5,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
          if (child != null) ...[const SizedBox(height: 16), child],
        ],
      ),
    );
  }

  Widget _buildToggleSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool enabled,
    required bool loading,
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
          Row(
            children: [
              Icon(
                icon,
                size: AdaptiveUtils.getTitleFontSize(width) + 5,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.7,
                child: loading
                    ? const AppShimmer(width: 38, height: 20, radius: 10)
                    : Switch(
                        value: value,
                        activeColor: colorScheme.onPrimary,
                        activeTrackColor: colorScheme.primary,
                        inactiveThumbColor: colorScheme.onPrimary,
                        inactiveTrackColor: colorScheme.primary.withOpacity(
                          0.3,
                        ),
                        onChanged: enabled ? onChanged : null,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
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
}

class _ApplicationSnapshot {
  final bool? demoEnabled;
  final String geocodingPrecision;
  final String backupRetention;
  final int? freeCredits;
  final bool? signupAllowed;

  const _ApplicationSnapshot({
    required this.demoEnabled,
    required this.geocodingPrecision,
    required this.backupRetention,
    required this.freeCredits,
    required this.signupAllowed,
  });
}
