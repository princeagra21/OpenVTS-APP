import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
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
  AdminAppPreferencesRepository? _repo;
  _Snapshot? _loadedSnapshot;

  AdminAppPreferencesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminAppPreferencesRepository(api: _apiClient!);
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
    _loadToken?.cancel('Application settings disposed');
    _saveToken?.cancel('Application settings disposed');
    super.dispose();
  }

  _Snapshot _defaultsSnapshot() {
    return const _Snapshot(
      demoEnabled: false,
      geocodingPrecision: '2 Digits',
      backupRetention: '3 Months',
      signupCredits: 0,
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
          final snapshot = _Snapshot(
            demoEnabled: prefs.allowDemoLogin ?? false,
            geocodingPrecision:
                prefs.geocodingPrecision == null
                    ? '2 Digits'
                    : (prefs.geocodingPrecision! >= 3
                        ? '3 Digits'
                        : '2 Digits'),
            backupRetention:
                prefs.backupRetentionLabel.isEmpty
                    ? '3 Months'
                    : prefs.backupRetentionLabel,
            signupCredits: prefs.signupCredits ?? 0,
            signupAllowed: prefs.allowSignup ?? true,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load settings.")),
      );
    }
  }

  Future<void> _savePreferences() async {
    if (_saving) return;
    _saveToken?.cancel('Resubmit app settings');
    _saveToken = CancelToken();
    if (!mounted) return;
    setState(() => _saving = true);

    try {
      // Backend currently accepts signup config keys for this screen.
      // Sending extra keys (demo/geocoding/backup) causes 400.
      final payload = <String, dynamic>{
        'allowSignup': signupAllowed,
        'signupCredits': signupCredits,
      };

      final res = await _repoOrCreate().updateAdminAppPreferences(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save settings.")),
      );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APPLICATION',
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: (_saving || _loading) ? null : _resetPressed,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.roboto(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saving ? null : _savePreferences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Save',
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
              const SizedBox(height: 4),
              Text(
                'Application Settings',
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure signup behavior for your company.',
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
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
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Allow New Signups',
                                  style: GoogleFonts.roboto(
                                    fontSize:
                                        AdaptiveUtils.getSubtitleFontSize(width) -
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
                    ),
                    const SizedBox(height: 12),
                    _numberField(
                      context,
                      label: 'Free Signup Credits*',
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
