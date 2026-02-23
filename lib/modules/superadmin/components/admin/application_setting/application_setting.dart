// screens/settings/application_settings_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/app_preferences.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/app_preferences_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplicationSettingsScreen extends StatelessWidget {
  const ApplicationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Settings",
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
  // Postman-confirmed endpoints for this screen:
  // - GET /superadmin/softwareconfig
  // - PATCH /superadmin/softwareconfig
  // Backend sample keys: allowDemoLogin, geocodingPrecision, backupDays, allowSignup, signupCredits.
  bool demoEnabled = false;
  String geocodingPrecision = "2 Digits";
  String backupRetention = "3 Months";
  int freeCredits = 0;
  bool signupAllowed = true;

  bool _loading = false;
  bool _saving = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  DateTime? _lastSaveAt;

  CancelToken? _loadToken;
  CancelToken? _saveToken;

  ApiClient? _apiClient;
  AppPreferencesRepository? _repo;

  _ApplicationSnapshot? _loadedSnapshot;

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
    _loadToken?.cancel('Application settings disposed');
    _saveToken?.cancel('Application settings disposed');
    super.dispose();
  }

  _ApplicationSnapshot _defaultsSnapshot() {
    return const _ApplicationSnapshot(
      demoEnabled: false,
      geocodingPrecision: '2 Digits',
      backupRetention: '3 Months',
      freeCredits: 0,
      signupAllowed: true,
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
  }

  void _showLoadErrorOnce(String message) {
    if (_loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadPreferences() async {
    _loadToken?.cancel('Reload app preferences');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getAppPreferences(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (prefs) {
          final mapped = _ApplicationSnapshot(
            demoEnabled: prefs.demoLoginEnabled,
            geocodingPrecision: prefs.reverseGeocodingDigits >= 3
                ? '3 Digits'
                : '2 Digits',
            backupRetention: prefs.backupRetention,
            freeCredits: prefs.freeSignupCredits,
            signupAllowed: prefs.allowSignup,
          );

          setState(() {
            _loading = false;
            _loadErrorShown = false;
            _applySnapshot(mapped);
            _loadedSnapshot = mapped;
          });
        },
        failure: (err) {
          setState(() => _loading = false);
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
      setState(() => _loading = false);
      _showLoadErrorOnce("Couldn't load settings.");
    }
  }

  Future<bool> _savePreferences({bool showSuccess = true}) async {
    if (_saving) return false;

    final now = DateTime.now();
    final last = _lastSaveAt;
    if (last != null && now.difference(last).inMilliseconds < 800) {
      return false;
    }
    _lastSaveAt = now;

    _saveToken?.cancel('Retry app preferences save');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return false;
    setState(() => _saving = true);

    final model = AppPreferences(const <String, dynamic>{});
    final payload = model.toPatchPayload(
      demoLoginEnabled: demoEnabled,
      reverseGeocodingDigits: geocodingPrecision == '3 Digits' ? 3 : 2,
      backupRetention: backupRetention,
      allowSignup: signupAllowed,
      freeSignupCredits: freeCredits,
    );

    try {
      final res = await _repoOrCreate().updateAppPreferences(
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
                ? 'Not authorized to update settings.'
                : "Couldn't save settings.";
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
          const SnackBar(content: Text("Couldn't save settings.")),
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
                AppShimmer(width: 90, height: 36, radius: 8),
                SizedBox(width: 12),
                AppShimmer(width: 86, height: 36, radius: 8),
              ],
            ),
            const SizedBox(height: 16),
            const AppShimmer(width: 220, height: 24, radius: 8),
            const SizedBox(height: 8),
            const AppShimmer(width: 320, height: 16, radius: 8),
            const SizedBox(height: 24),
            _buildLoadingShimmer(width),
          ],
        ),
      );
    }

    String demoStatus = demoEnabled ? "ON" : "OFF";
    String signupStatus = signupAllowed ? "ALLOWED" : "DISABLED";

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
          // TOP BUTTONS (Reset & Save)
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
                    : () => _savePreferences(showSuccess: true),
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
            "Application Settings",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configure system-wide settings for your application.",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width),
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 24),

          // CURRENT CONFIGURATION
          _buildSection(
            context: context,
            icon: Icons.settings_rounded,
            title: "Current Configuration",
            child: Text(
              "Demo: $demoStatus • Geocoding: $geocodingPrecision • Signup: $signupStatus",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // DEMO LOGIN
          _buildToggleSection(
            context: context,
            icon: Icons.login_rounded,
            title: "Demo Login",
            subtitle: demoEnabled
                ? "Demo login is enabled"
                : "Demo login is disabled",
            value: demoEnabled,
            onChanged: _saving
                ? (_) {}
                : (v) => setState(() => demoEnabled = v),
          ),

          const SizedBox(height: 24),

          // REVERSE GEOCODING
          _buildSection(
            context: context,
            icon: Icons.location_on_rounded,
            title: "Reverse Geocoding",
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("2 Digits\nCity/Region"),
                  selected: geocodingPrecision == "2 Digits",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    color: geocodingPrecision == "2 Digits"
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  onSelected: (_) {
                    if (_saving) return;
                    setState(() => geocodingPrecision = "2 Digits");
                  },
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text("3 Digits\nStreet Level"),
                  selected: geocodingPrecision == "3 Digits",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    color: geocodingPrecision == "3 Digits"
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                  onSelected: (_) {
                    if (_saving) return;
                    setState(() => geocodingPrecision = "3 Digits");
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DATABASE BACKUP
          _buildSection(
            context: context,
            icon: Icons.backup_rounded,
            title: "Database Backup",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: backupRetention,
                  decoration: _dropdownDecoration(context),
                  items: ["1 Month", "3 Months", "6 Months", "12 Months"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (_saving) return;
                    if (v != null) setState(() => backupRetention = v);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  "Backups will be retained for the selected period",
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SIGNUP CONFIGURATION
          _buildSection(
            context: context,
            icon: Icons.person_add_rounded,
            title: "Signup Configuration",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Allow New Signups",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: signupAllowed,
                        activeColor: colorScheme.onPrimary,
                        activeTrackColor: colorScheme.primary,
                        inactiveThumbColor: colorScheme.onPrimary,
                        inactiveTrackColor: colorScheme.primary.withOpacity(
                          0.3,
                        ),
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => signupAllowed = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  signupAllowed
                      ? "New users can register"
                      : "New user registration is disabled",
                  style: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Free Signup Credits",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller:
                      TextEditingController(text: freeCredits.toString())
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: freeCredits.toString().length),
                        ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    if (_saving) return;
                    setState(
                      () => freeCredits = int.tryParse(v) ?? freeCredits,
                    );
                  },
                  style: GoogleFonts.inter(color: colorScheme.onSurface),
                  decoration: _inputDecoration(
                    context,
                    hint:
                        "Number of free credits awarded to new users upon signup",
                  ),
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
        _buildShimmerCard(width: width, titleWidth: 220, fields: 1),
        const SizedBox(height: 24),
        _buildShimmerCard(width: width, titleWidth: 180, fields: 2),
        const SizedBox(height: 24),
        _buildShimmerCard(width: width, titleWidth: 170, fields: 2),
        const SizedBox(height: 24),
        _buildShimmerCard(width: width, titleWidth: 230, fields: 3),
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
                child: Switch(
                  value: value,
                  activeColor: colorScheme.onPrimary,
                  activeTrackColor: colorScheme.primary,
                  inactiveThumbColor: colorScheme.onPrimary,
                  inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                  onChanged: _saving ? null : onChanged,
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
  final bool demoEnabled;
  final String geocodingPrecision;
  final String backupRetention;
  final int freeCredits;
  final bool signupAllowed;

  const _ApplicationSnapshot({
    required this.demoEnabled,
    required this.geocodingPrecision,
    required this.backupRetention,
    required this.freeCredits,
    required this.signupAllowed,
  });
}
