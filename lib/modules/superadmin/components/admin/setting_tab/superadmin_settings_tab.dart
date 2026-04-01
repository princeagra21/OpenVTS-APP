import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/app_preferences.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/app_preferences_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuperadminSettingsTab extends StatefulWidget {
  const SuperadminSettingsTab({super.key});

  @override
  State<SuperadminSettingsTab> createState() => _SuperadminSettingsTabState();
}

class _SuperadminSettingsTabState extends State<SuperadminSettingsTab> {
  bool demoEnabled = false;
  String geocodingPrecision = '2 Digits';
  String backupRetention = '3 Months';
  int signupCredits = 0;
  bool signupAllowed = true;

  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;

  CancelToken? _loadToken;
  CancelToken? _saveToken;

  ApiClient? _apiClient;
  AppPreferencesRepository? _repo;
  _Snapshot? _loadedSnapshot;

  AppPreferencesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AppPreferencesRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadedSnapshot = _defaultsSnapshot();
    _loadPreferences();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Superadmin settings disposed');
    _saveToken?.cancel('Superadmin settings disposed');
    super.dispose();
  }

  _Snapshot _defaultsSnapshot() {
    return const _Snapshot(
      demoEnabled: false,
      geocodingPrecision: '2 Digits',
      backupRetention: '3 Months',
      signupCredits: 1000,
      signupAllowed: true,
    );
  }

  _Snapshot _captureSnapshot() {
    return _Snapshot(
      demoEnabled: demoEnabled,
      geocodingPrecision: geocodingPrecision,
      backupRetention: backupRetention,
      signupCredits: signupCredits,
      signupAllowed: signupAllowed,
    );
  }

  void _applySnapshot(_Snapshot snapshot) {
    demoEnabled = snapshot.demoEnabled;
    geocodingPrecision = snapshot.geocodingPrecision;
    backupRetention = snapshot.backupRetention;
    signupCredits = snapshot.signupCredits;
    signupAllowed = snapshot.signupAllowed;
  }

  Future<void> _loadPreferences() async {
    _loadToken?.cancel('Reload software config');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getAppPreferences(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (prefs) {
          final snapshot = _Snapshot(
            demoEnabled: prefs.demoLoginEnabled,
            geocodingPrecision:
                prefs.reverseGeocodingDigits == 3 ? '3 Digits' : '2 Digits',
            backupRetention: prefs.backupRetention,
            signupCredits: prefs.freeSignupCredits,
            signupAllowed: prefs.allowSignup,
          );
          setState(() {
            _loading = false;
            _loadedSnapshot = snapshot;
            _applySnapshot(snapshot);
          });
        },
        failure: (err) {
          setState(() => _loading = false);
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          final msg = (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load settings.'
              : "Couldn't load settings.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Couldn't load settings.")));
    }
  }

  Future<void> _savePreferences() async {
    if (_saving) return;
    _saveToken?.cancel('Resubmit software config');
    _saveToken = CancelToken();
    if (!mounted) return;
    setState(() => _saving = true);

    try {
      final prefs = AppPreferences(const {});
      final payload = prefs.toPatchPayload(
        demoLoginEnabled: demoEnabled,
        reverseGeocodingDigits: geocodingPrecision.contains('3') ? 3 : 2,
        backupRetention: backupRetention,
        allowSignup: signupAllowed,
        freeSignupCredits: signupCredits,
      );
      final res = await _repoOrCreate().updateAppPreferences(
        payload,
        cancelToken: _saveToken,
      );

      if (!mounted) return;
      res.when(
        success: (_) {
          setState(() {
            _saving = false;
            _loadedSnapshot = _captureSnapshot();
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Saved')));
        },
        failure: (err) {
          setState(() => _saving = false);
          if (_saveErrorShown) return;
          _saveErrorShown = true;
          final msg = (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to save settings.'
              : "Couldn't save settings.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (_saveErrorShown) return;
      _saveErrorShown = true;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Couldn't save settings.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double labelFs = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueFs = AdaptiveUtils.getSubtitleFontSize(width) - 2;

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
          children: const [
            AppShimmer(width: 180, height: 18, radius: 8),
            SizedBox(height: 16),
            AppShimmer(width: double.infinity, height: 48, radius: 12),
            SizedBox(height: 12),
            AppShimmer(width: double.infinity, height: 48, radius: 12),
          ],
        ),
      );
    }

    return Column(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Application',
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: (_saving || _loading)
                        ? null
                        : () {
                            final snapshot = _loadedSnapshot;
                            if (snapshot == null) return;
                            setState(() => _applySnapshot(snapshot));
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
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
                    onPressed: _saving ? null : _savePreferences,
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
                          ? const AppShimmer(width: 18, height: 18, radius: 9)
                          : Icon(
                              Icons.save_outlined,
                              color: colorScheme.onPrimary,
                            ),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Configuration',
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Demo Login: ${demoEnabled ? 'ENABLED' : 'DISABLED'} · '
                  'Reverse Geocoding: $geocodingPrecision · '
                  'Signup: ${signupAllowed ? 'ALLOWED' : 'DISABLED'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: labelFs,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Login',
                      style: GoogleFonts.roboto(
                        fontSize: labelFs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demoEnabled ? 'Enabled' : 'Disabled',
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 1,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Retention',
                      style: GoogleFonts.roboto(
                        fontSize: labelFs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      backupRetention,
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 1,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Signup Credits',
                      style: GoogleFonts.roboto(
                        fontSize: labelFs,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signupCredits.toString(),
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 1,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? colorScheme.surfaceVariant
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.toggle_on_outlined,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Login',
                        style: GoogleFonts.roboto(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        demoEnabled ? 'Disable Demo Login' : 'Enable Demo Login',
                        style: GoogleFonts.roboto(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.7),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Users can access demo mode',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 1,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Switch(
                    value: demoEnabled,
                    onChanged: (v) => setState(() => demoEnabled = v),
                    activeColor: colorScheme.primary,
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? colorScheme.surfaceVariant
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.location_searching_outlined,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reverse Geocoding',
                        style: GoogleFonts.roboto(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Address Precision',
                        style: GoogleFonts.roboto(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.7),
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
                          onTap: () => setState(() {
                            geocodingPrecision = '2 Digits';
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: geocodingPrecision.contains('2')
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "2 Digits",
                                style: GoogleFonts.roboto(
                                  color: geocodingPrecision.contains('2')
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            geocodingPrecision = '3 Digits';
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: geocodingPrecision.contains('3')
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "3 Digits",
                                style: GoogleFonts.roboto(
                                  color: geocodingPrecision.contains('3')
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
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
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.backup_outlined,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Database Backup',
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withOpacity(0.87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Retention Period',
                            style: GoogleFonts.roboto(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: backupRetention,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1 Month', child: Text('1 Month')),
                    DropdownMenuItem(value: '3 Months', child: Text('3 Months')),
                    DropdownMenuItem(value: '6 Months', child: Text('6 Months')),
                    DropdownMenuItem(value: '12 Months', child: Text('12 Months')),
                  ],
                  onChanged: (v) =>
                      setState(() => backupRetention = v ?? backupRetention),
                  style: GoogleFonts.roboto(
                    fontSize: valueFs,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Backups will be retained for the selected period',
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
              Text(
                'Signup Configuration',
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Allow New Signups',
                                style: GoogleFonts.roboto(
                                  fontSize: AdaptiveUtils
                                          .getSubtitleFontSize(width) -
                                      3,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface.withOpacity(0.87),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'New users can register',
                                style: GoogleFonts.roboto(
                                  fontSize:
                                      AdaptiveUtils.getSubtitleFontSize(width) -
                                          3,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: signupAllowed,
                          onChanged: (v) => setState(() => signupAllowed = v),
                          activeColor: colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _numberField(
                context,
                label: 'Free Signup Credits',
                value: signupCredits,
                onChanged: (v) => setState(() => signupCredits = v),
                labelFs: AdaptiveUtils.getTitleFontSize(width) + 2,
                valueFs: valueFs,
                colorScheme: colorScheme,
                labelWeight: FontWeight.w800,
                labelColor: colorScheme.onSurface.withOpacity(0.87),
              ),
              const SizedBox(height: 6),
              Text(
                'Number of free credits awarded to new users upon signup',
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double labelFs,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: labelFs,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: colorScheme.primary,
        ),
      ],
    );
  }

  Widget _dropdownField(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    required double labelFs,
    required double valueFs,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: labelFs,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
          style: GoogleFonts.roboto(
            fontSize: valueFs,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _numberField(
    BuildContext context, {
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required double labelFs,
    required double valueFs,
    required ColorScheme colorScheme,
    FontWeight? labelWeight,
    Color? labelColor,
  }) {
    final controller = TextEditingController(text: value.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: labelFs,
            fontWeight: labelWeight ?? FontWeight.w600,
            color: labelColor ?? colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.roboto(
            fontSize: valueFs,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          onChanged: (v) => onChanged(int.tryParse(v) ?? value),
        ),
      ],
    );
  }
}

class _Snapshot {
  final bool demoEnabled;
  final String geocodingPrecision;
  final String backupRetention;
  final int signupCredits;
  final bool signupAllowed;

  const _Snapshot({
    required this.demoEnabled,
    required this.geocodingPrecision,
    required this.backupRetention,
    required this.signupCredits,
    required this.signupAllowed,
  });
}
