// components/admin/profile_tab.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/services/push_notifications_service.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/edit_company_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/update_password_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/edit_admin_profile_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/widget/delete_account_box.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileTab extends StatefulWidget {
  final String adminId;
  final VoidCallback? onStatusChanged;
  final bool? initialActive;

  const ProfileTab({
    super.key,
    required this.adminId,
    this.onStatusChanged,
    this.initialActive,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  AdminProfile? _profile;
  bool _loading = false;
  bool _statusSubmitting = false;
  bool? _activeOverride;
  bool _errorShown = false;
  bool _loadFailed = false;
  CancelToken? _token;
  bool _pushActionLoading = false;
  PushDeviceState? _pushState;

  ApiClient? _api;
  SuperadminRepository? _repo;

  bool get _isActive => _activeOverride ?? _profile?.isActive == true;

  bool? _readActive(AdminProfile profile) {
    final d = profile.data;
    dynamic v = d['isActive'] ?? d['active'] ?? d['is_active'] ?? d['status'];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final t = v.toString().trim().toLowerCase();
    if (t == 'true' || t == '1' || t == 'active' || t == 'enabled') {
      return true;
    }
    if (t == 'false' || t == '0' || t == 'inactive' || t == 'disabled') {
      return false;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _activeOverride = widget.initialActive;
    _loadProfile();
    _loadPushState();
  }

  @override
  void dispose() {
    _token?.cancel('ProfileTab disposed');
    super.dispose();
  }

  Future<void> _loadPushState() async {
    final state = await PushNotificationsService.instance.getStatus();
    if (!mounted) return;
    setState(() {
      _pushState = state;
    });
  }

  Future<void> _openNotificationSettings() async {
    final uri = Uri.parse('app-settings:');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Open your device settings and allow notifications for this app.",
        ),
      ),
    );
  }

  Future<void> _openExternalLink(String rawUrl) async {
    final text = rawUrl.trim();
    if (text.isEmpty || text == '-') return;
    final normalized = text.startsWith('http://') || text.startsWith('https://')
        ? text
        : 'https://$text';
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid link')));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  Future<void> _handlePushRegister() async {
    if (_pushActionLoading) return;
    setState(() => _pushActionLoading = true);
    final res = await PushNotificationsService.instance.enable();
    if (!mounted) return;
    res.when(
      success: (state) {
        setState(() {
          _pushState = state;
          _pushActionLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Push enabled.')));
      },
      failure: (err) async {
        setState(() => _pushActionLoading = false);
        final msg = err is ApiException
            ? (err.message ?? 'Push could not be enabled.')
            : 'Push could not be enabled.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        if (err is ApiException &&
            err.message.toLowerCase().contains('permission')) {
          await _showPushPermissionDialog();
        }
      },
    );
  }

  Future<void> _handlePushUnregister() async {
    if (_pushActionLoading) return;
    setState(() => _pushActionLoading = true);
    final res = await PushNotificationsService.instance.disable();
    if (!mounted) return;
    res.when(
      success: (_) async {
        await _loadPushState();
        if (!mounted) return;
        setState(() => _pushActionLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Push disabled.')));
      },
      failure: (err) {
        setState(() => _pushActionLoading = false);
        final msg = err is ApiException
            ? (err.message ?? 'Push could not be disabled.')
            : 'Push could not be disabled.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
  }

  Future<void> _showPushPermissionDialog() async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (_) => const _PushSettingsDialog(),
    );
    if (shouldOpen == true) {
      await _openNotificationSettings();
    }
  }

  Future<void> _confirmPushAction() async {
    final state =
        _pushState ?? await PushNotificationsService.instance.getStatus();
    if (!mounted) return;

    if (state.registered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const _PushUnregisterDialog(),
      );
      if (confirmed == true) {
        await _handlePushUnregister();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _PushRegisterDialog(),
    );
    if (confirmed == true) {
      await _handlePushRegister();
    }
  }

  Future<void> _handlePushTest() async {
    final messenger = ScaffoldMessenger.of(context);
    final state =
        _pushState ?? await PushNotificationsService.instance.getStatus();
    if (!mounted) return;

    if (!state.registered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const _PushRegisterDialog(
          title: 'Enable push to test?',
          message:
              'Push is not enabled yet. Turn it on so we can send a test notification to this device.',
          confirmLabel: 'Enable',
        ),
      );
      if (confirmed == true) {
        await _handlePushRegister();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _PushTestDialog(),
    );
    if (confirmed != true) return;

    messenger.showSnackBar(const SnackBar(content: Text('Test push queued.')));
  }

  Future<void> _openCompanyEdit() async {
    final profile = _profile;
    if (profile == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCompanyScreen(profile: profile),
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      await _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    _token?.cancel('Reload admin profile');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getAdminProfile(
        widget.adminId,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (!mounted) return;
          final active = _readActive(profile);
          setState(() {
            _profile = profile;
            _loading = false;
            _errorShown = false;
            _loadFailed = false;
            if (active != null) {
              _activeOverride = active;
            }
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _loadFailed = true;
          });
          if (_errorShown) return;
          _errorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view admin profile.'
              : "Couldn't load admin profile.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              action: SnackBarAction(label: 'Retry', onPressed: _loadProfile),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't load admin profile."),
          action: SnackBarAction(label: 'Retry', onPressed: _loadProfile),
        ),
      );
    }
  }

  Future<void> _toggleActive() async {
    if (_statusSubmitting) return;
    final profile = _profile;
    if (profile == null) return;
    setState(() => _statusSubmitting = true);
    final currentActive = _activeOverride ?? profile.isActive;
    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final res = await _repo!.updateAdminStatus(
        widget.adminId,
        !currentActive,
      );
      if (!mounted) return;
      res.when(
        success: (_) async {
          setState(() => _activeOverride = !currentActive);
          widget.onStatusChanged?.call();
          await _loadProfile();
          if (!mounted) return;
          setState(() => _statusSubmitting = false);
        },
        failure: (_) {
          if (!mounted) return;
          setState(() => _statusSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't update status.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update status.")),
      );
    }
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double fs = 14 * scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildOverviewCard(
          context,
          padding: padding,
          fs: fs,
          colorScheme: colorScheme,
          loading: _loading,
        ),
        SizedBox(height: padding),
        /* _buildPushDiagnosticsCard(context, fs: fs, colorScheme: colorScheme), */
        if (_loadFailed) ...[
          const SizedBox(height: 16),
          TextButton(onPressed: _loadProfile, child: const Text('Retry')),
        ],
        const SizedBox(height: 24),
        DeleteAccountBox(adminId: widget.adminId),
      ],
    ); // Added CompanyBox below AdminInfoBoxes
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required double padding,
    required double fs,
    required ColorScheme colorScheme,
    required bool loading,
  }) {
    final double scale = fs / 14;
    final double fsSection = 18 * scale;
    final double fsAction = 14 * scale;
    final double fsActionIcon = 16 * scale;
    final p = _profile;
    final displayName = _display(p?.fullName, fallback: _display(p?.username));
    final username = _usernameLabel(_display(p?.username));
    final email = _display(p?.email);
    final phone = _display(p?.phone);
    final isVerified = p?.isVerified == true;
    final companyName = _display(p?.companyName);
    final socialLinks = _companySocialLinks(p);
    final websiteUrl = _valueFromKeys(p, const [
      'websiteUrl',
      'website',
      'siteUrl',
    ]);
    final customDomain = _valueFromKeys(p, const [
      'customDomain',
      'custom_domain',
      'domain',
      'website',
      'websiteUrl',
    ]);
    final primaryColor = _valueFromKeys(p, const [
      'primaryColor',
      'primary_color',
      'brandColor',
      'brand_color',
    ]);
    final favicon = _valueFromKeys(p, const [
      'favicon',
      'faviconUrl',
      'favicon_url',
    ]);
    final logoLight = _valueFromKeys(p, const [
      'logoLight',
      'logo_light',
      'logoLightUrl',
      'logo_light_url',
    ]);
    final logoDark = _valueFromKeys(p, const [
      'logoDark',
      'logo_dark',
      'logoDarkUrl',
      'logo_dark_url',
    ]);
    final company = _display(p?.companyName);
    final address = _buildAddress(p);
    final updatedRaw = _firstNonEmpty([
      p?.data['updatedAt']?.toString(),
      p?.data['updated_at']?.toString(),
    ]);
    final createdRaw = _firstNonEmpty([
      p?.createdAt,
      p?.data['createdAt']?.toString(),
      p?.data['created_at']?.toString(),
    ]);
    final updated = _formatDateTime(updatedRaw);
    final created = _formatDateTime(createdRaw);
    final vehiclesCount = p?.vehiclesCount ?? 0;
    final credits = p?.credits ?? 0;
    final lastLogin = _formatDateTime(p?.lastLogin ?? '');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Admin Overview",
                    style: GoogleFonts.roboto(
                      fontSize: fsSection,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditAdminProfileScreen(adminId: widget.adminId),
                        ),
                      ).then((updated) {
                        if (updated == true) {
                          _loadProfile();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.edit,
                      size: fsActionIcon,
                      color: colorScheme.onPrimary,
                    ),
                    label: Text(
                      "Edit",
                      style: GoogleFonts.roboto(
                        fontSize: fsAction,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _statusSubmitting ? null : _toggleActive,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _isActive
                          ? Icons.toggle_on
                          : Icons.toggle_off,
                      size: fsActionIcon,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      _isActive
                          ? "Set Inactive"
                          : "Set Active",
                      style: GoogleFonts.roboto(
                        fontSize: fsAction,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdatePasswordScreen(
                            adminId: widget.adminId,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.lock_outline,
                      size: fsActionIcon,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      "Password",
                      style: GoogleFonts.roboto(
                        fontSize: fsAction,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: padding),
          _buildAccountCard(
            context,
            name: displayName,
            username: username,
            email: email,
            phone: phone,
            isVerified: isVerified,
            loading: loading,
            fs: fs,
            colorScheme: colorScheme,
          ),
          SizedBox(height: padding),
          _buildAdminMetaGrid(
            context,
            fs: fs,
            colorScheme: colorScheme,
            loading: loading,
            vehiclesCount: vehiclesCount.toString(),
            credits: credits.toString(),
            lastLogin: lastLogin,
            created: created,
          ),
          SizedBox(height: padding),
          _buildCompanyCard(
            context,
            fs: fs,
            colorScheme: colorScheme,
            companyName: companyName,
            websiteUrl: websiteUrl,
            customDomain: customDomain,
            primaryColor: primaryColor,
            favicon: favicon,
            logoLight: logoLight,
            logoDark: logoDark,
            socialLinks: socialLinks,
            loading: loading,
          ),
          SizedBox(height: padding),
          _buildAddressCard(
            context,
            fs: fs,
            colorScheme: colorScheme,
            address: address,
            addressId: _addressValue(p, const [
              'id',
              'addressId',
              'address_id',
              'addressID',
            ]),
            line: _addressValue(p, const ['addressLine', 'address_line']),
            city: _addressValue(p, const ['cityId', 'city', 'cityName']),
            state: _addressValue(p, const ['stateCode', 'state', 'stateName']),
            postal: _addressValue(p, const ['pincode', 'postalCode']),
            country: _addressValue(p, const ['countryCode', 'country']),
            loading: loading,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required String name,
    required String username,
    required String email,
    required String phone,
    required bool isVerified,
    required bool loading,
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double avatarSize = 40 * scale;
    final double labelFs = 11 * scale;
    final double titleFs = 14 * scale;
    final double subtitleFs = 12 * scale;
    final double statusFs = 11 * scale;
    final double statusIcon = 12 * scale;
    final double rowIcon = 14 * scale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surfaceVariant
                      : Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: loading
                    ? const AppShimmer(width: 24, height: 24, radius: 12)
                    : Text(
                        name.isNotEmpty ? name.trim()[0].toUpperCase() : 'A',
                        style: GoogleFonts.roboto(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: loading
                              ? const AppShimmer(
                                  width: 120,
                                  height: 18,
                                  radius: 8,
                                )
                              : Text(
                                  name,
                                  style: GoogleFonts.roboto(
                                    fontSize: titleFs,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        loading
                            ? const AppShimmer(
                                width: 90,
                                height: 18,
                                radius: 999,
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? colorScheme.surfaceVariant
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _isActive
                                      ? "Active"
                                      : "Inactive",
                                  style: GoogleFonts.roboto(
                                    fontSize: statusFs,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    loading
                        ? const AppShimmer(width: 120, height: 14, radius: 8)
                        : Text(
                            username,
                            style: GoogleFonts.roboto(
                              fontSize: subtitleFs,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                    const SizedBox(height: 6),
                    loading
                        ? const AppShimmer(width: 140, height: 14, radius: 8)
                        : Text(
                            phone,
                            style: GoogleFonts.roboto(
                              fontSize: subtitleFs,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                    const SizedBox(height: 6),
                    loading
                        ? const AppShimmer(width: 160, height: 14, radius: 8)
                        : Text(
                            email,
                            style: GoogleFonts.roboto(
                              fontSize: subtitleFs,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMetaGrid(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required bool loading,
    required String vehiclesCount,
    required String credits,
    required _DatePair lastLogin,
    required _DatePair created,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gap = 10;
        final double cellWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Vehicles",
                pair: _DatePair(vehiclesCount, ''),
                fs: fs,
                colorScheme: colorScheme,
                loading: loading,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Credits",
                pair: _DatePair(credits, ''),
                fs: fs,
                colorScheme: colorScheme,
                loading: loading,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Last Login",
                pair: lastLogin,
                fs: fs,
                colorScheme: colorScheme,
                loading: loading,
              ),
            ),
            SizedBox(
              width: cellWidth,
              child: _dateCard(
                title: "Created",
                pair: created,
                fs: fs,
                colorScheme: colorScheme,
                loading: loading,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dateCard({
    required String title,
    required _DatePair pair,
    required double fs,
    required ColorScheme colorScheme,
    required bool loading,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 14 * scale;
    final double subValueFs = 12 * scale;
    IconData _titleIcon(String t) {
      final l = t.toLowerCase();
      if (l.contains('vehicle')) return Icons.directions_car_outlined;
      if (l.contains('credit')) return Icons.account_balance_wallet_outlined;
      if (l.contains('login')) return Icons.schedule;
      if (l.contains('created')) return Icons.event;
      return Icons.info_outline;
    }
    final hasSub = pair.time.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: labelFs,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              Icon(
                _titleIcon(title),
                size: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 10),
          loading
              ? const AppShimmer(width: 120, height: 18, radius: 8)
              : Text(
                  pair.date,
                  style: GoogleFonts.roboto(
                    fontSize: valueFs + 2,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
          if (hasSub) ...[
            const SizedBox(height: 6),
            loading
                ? const AppShimmer(width: 90, height: 14, radius: 8)
                : Text(
                    pair.time,
                    style: GoogleFonts.roboto(
                      fontSize: subValueFs,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 14 * scale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: labelFs,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required String companyName,
    required String websiteUrl,
    required String customDomain,
    required String primaryColor,
    required String favicon,
    required String logoLight,
    required String logoDark,
    required List<_CompanyLink> socialLinks,
    required bool loading,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double titleFs = 14 * scale;
    final double iconBox = 40 * scale;
    final double iconSize = 18 * scale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surfaceVariant
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.apartment,
                  size: iconSize,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Company",
                      style: GoogleFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    loading
                        ? const AppShimmer(
                            width: 180,
                            height: 18,
                            radius: 8,
                          )
                        : Text(
                            companyName,
                            style: GoogleFonts.roboto(
                              fontSize: titleFs,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                    if (!loading && websiteUrl != '-') ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openExternalLink(websiteUrl),
                        child: Text(
                          websiteUrl,
                          style: GoogleFonts.roboto(
                            fontSize: labelFs,
                            height: 14 / 11,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!loading) ...[
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openCompanyEdit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.14),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!loading && socialLinks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: iconBox + 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: socialLinks
                    .map(
                      (link) => InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _openExternalLink(link.url),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? colorScheme.surfaceVariant
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.onSurface.withOpacity(0.12),
                            ),
                          ),
                          child: Text(
                            link.label,
                            style: GoogleFonts.roboto(
                              fontSize: labelFs,
                              height: 14 / 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
    required String address,
    required String addressId,
    required String line,
    required String city,
    required String state,
    required String postal,
    required String country,
    required bool loading,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double titleFs = 14 * scale;
    final double iconBox = 40 * scale;
    final double iconSize = 18 * scale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surfaceVariant
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on_outlined,
                  size: iconSize,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Address",
                      style: GoogleFonts.roboto(
                        fontSize: labelFs,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    loading
                        ? const AppShimmer(
                            width: double.infinity,
                            height: 16,
                            radius: 8,
                          )
                        : Text(
                            address,
                            style: GoogleFonts.roboto(
                              fontSize: titleFs,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _keyValueRow("Address ID", addressId, fs, colorScheme, loading),
          const SizedBox(height: 8),
          _keyValueRow("Line", line, fs, colorScheme, loading),
          const SizedBox(height: 8),
          _keyValueRow("City", city, fs, colorScheme, loading),
          const SizedBox(height: 8),
          _keyValueRow("State", state, fs, colorScheme, loading),
          const SizedBox(height: 8),
          _keyValueRow("Postal", postal, fs, colorScheme, loading),
          const SizedBox(height: 8),
          _keyValueRow("Country", country, fs, colorScheme, loading),
        ],
      ),
    );
  }

  List<_CompanyLink> _companySocialLinks(AdminProfile? profile) {
    final data = profile?.data;
    if (data == null) return const [];
    Map<String, dynamic>? company;
    final companies = data['companies'];
    if (companies is List && companies.isNotEmpty && companies.first is Map) {
      company = Map<String, dynamic>.from(
        companies.first as Map,
      );
    }
    company ??= data['company'] is Map
        ? Map<String, dynamic>.from(data['company'] as Map)
        : null;
    final links = <_CompanyLink>[];

    void addLink(String label, Object? value) {
      final v = (value?.toString() ?? '').trim();
      if (v.isEmpty || v == '-') return;
      if (links.any((e) => e.url == v)) return;
      links.add(_CompanyLink(label: label, url: v));
    }

    final social = company?['socialLinks'] ?? _deepFindKey(data, 'socialLinks');
    if (social is Map) {
      social.forEach((key, value) {
        addLink(_titleCaseKey(key.toString()), value);
      });
    }

    // Fallbacks when API returns social links outside company.socialLinks.
    addLink(
      'Custom Domain',
      _deepFindAnyKey(data, const ['customDomain', 'domain', 'custom_domain']),
    );
    addLink('Facebook', _deepFindAnyKey(data, const ['facebook']));
    addLink('Instagram', _deepFindAnyKey(data, const ['instagram']));
    addLink('Linkedin', _deepFindAnyKey(data, const ['linkedin']));
    addLink('Twitter', _deepFindAnyKey(data, const ['twitter', 'x']));

    return links;
  }

  String _titleCaseKey(String key) {
    final cleaned = key.replaceAll(RegExp(r'[_\\-]+'), ' ').trim();
    if (cleaned.isEmpty) return key;
    return cleaned
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Widget _buildPushDiagnosticsCard(
    BuildContext context, {
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double headingFs = 18 * scale;
    final double subtitleFs = 12 * scale;
    final double alertFs = 12 * scale;
    final state = _pushState;
    final permissionLabel = state == null
        ? 'Checking...'
        : (!state.supported
            ? 'Unsupported'
            : (state.registered
                ? 'Allowed'
                : (state.askedOnce ? 'Blocked' : 'Not requested')));
    final tokenLabel = state == null
        ? '—'
        : (state.token?.isNotEmpty == true ? 'Registered' : 'None');
    final showPermissionWarning =
        state != null && state.supported && !state.enabledByUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Push Diagnostics",
            style: GoogleFonts.roboto(
              fontSize: headingFs,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Notification permission and push state",
            style: GoogleFonts.roboto(
              fontSize: subtitleFs,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double gap = 10;
              final double cellWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: "Permission",
                      value: permissionLabel,
                      fs: fs,
                      colorScheme: colorScheme,
                    ),
                  ),
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: "Server Tokens",
                      value: tokenLabel,
                      fs: fs,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              );
            },
          ),
          if (showPermissionWarning) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16 * scale,
                        color: Colors.orange,
                      ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Notifications are blocked. Open your device settings and allow notifications, then click 'Re-register push'.",
                      style: GoogleFonts.roboto(
                        fontSize: alertFs,
                        height: 17 / 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pushActionLoading ? null : _confirmPushAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    (_pushState?.registered ?? false)
                        ? Icons.notifications_off
                        : Icons.refresh,
                    size: 16 * scale,
                    color: colorScheme.onPrimary,
                  ),
                  label: Text(
                    (_pushState?.registered ?? false)
                        ? "Unregister push"
                        : "Re-register push",
                    style: GoogleFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pushActionLoading ? null : _handlePushTest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.send,
                    size: 16 * scale,
                    color: colorScheme.onSurface,
                  ),
                  label: Text(
                    "Send push test",
                    style: GoogleFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pushInfoBox({
    required String title,
    required String value,
    required double fs,
    required ColorScheme colorScheme,
  }) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 14 * scale;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: labelFs,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyValueRow(
    String label,
    String value,
    double fs,
    ColorScheme colorScheme,
    bool loading,
  ) {
    final double scale = fs / 14;
    final double labelFs = 11 * scale;
    final double valueFs = 12 * scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: labelFs,
            height: 14 / 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Flexible(
          child: loading
              ? const Align(
                  alignment: Alignment.centerRight,
                  child: AppShimmer(width: 120, height: 14, radius: 8),
                )
              : Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: valueFs,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
        ),
      ],
    );
  }

  String _buildAddress(AdminProfile? p) {
    if (p == null) return '-';
    final fullAddress = _valueFromKeys(p, const [
      'fulladdress',
      'fullAddress',
      'addressFull',
      'address_full',
    ]);
    if (fullAddress != '-') return fullAddress;
    final addressMap = p.data['address'];
    if (addressMap is Map) {
      final nested = addressMap['fullAddress'] ??
          addressMap['fulladdress'] ??
          addressMap['addressFull'] ??
          addressMap['address_full'];
      if (nested != null && nested.toString().trim().isNotEmpty) {
        return nested.toString().trim();
      }
    }
    final parts = <String>[
      _display(p.addressLine),
      _display(p.city),
      _display(p.state),
      _display(p.pincode),
      _display(p.country),
    ].where((e) => e != '-').toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  String _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v == null) continue;
      final t = v.trim();
      if (t.isNotEmpty) return t;
    }
    return '-';
  }

  String _valueFromKeys(AdminProfile? p, List<String> keys) {
    if (p == null) return '-';
    for (final key in keys) {
      final v = p.data[key];
      if (v == null) continue;
      final t = v.toString().trim();
      if (t.isNotEmpty) return t;
    }
    final company = p.data['company'];
    if (company is Map) {
      final map = Map<String, dynamic>.from(company.cast());
      for (final key in keys) {
        final v = map[key];
        if (v == null) continue;
        final t = v.toString().trim();
        if (t.isNotEmpty) return t;
      }
    }
    final deep = _deepFindAnyKey(p.data, keys);
    if (deep != null) {
      final t = deep.toString().trim();
      if (t.isNotEmpty) return t;
    }
    return '-';
  }

  Object? _deepFindAnyKey(Map<String, dynamic> root, List<String> keys) {
    for (final key in keys) {
      final found = _deepFindKey(root, key);
      if (found != null && found.toString().trim().isNotEmpty) return found;
    }
    return null;
  }

  Object? _deepFindKey(Map<String, dynamic> root, String key) {
    if (root.containsKey(key)) return root[key];
    for (final value in root.values) {
      if (value is Map) {
        final nested = Map<String, dynamic>.from(value.cast());
        final found = _deepFindKey(nested, key);
        if (found != null) return found;
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final nested = Map<String, dynamic>.from(item.cast());
            final found = _deepFindKey(nested, key);
            if (found != null) return found;
          }
        }
      }
    }
    return null;
  }

  String _addressValue(AdminProfile? p, List<String> keys) {
    if (p == null) return '-';
    final addressMap = p.data['address'];
    if (addressMap is Map) {
      for (final key in keys) {
        final v = addressMap[key];
        if (v == null) continue;
        final t = v.toString().trim();
        if (t.isNotEmpty) return t;
      }
    }
    return _valueFromKeys(p, keys);
  }

  _DatePair _formatDateTime(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '-') {
      return const _DatePair('-', '-');
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return _DatePair(text, '-');
    }
    final local = parsed.toLocal();
    final date =
        '${local.month}/${local.day}/${local.year}';
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String minute = local.minute.toString().padLeft(2, '0');
    final String ampm = local.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour12:$minute $ampm';
    return _DatePair(date, time);
  }

  String _display(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _usernameLabel(String username) {
    if (username == '-') return '-';
    return username.startsWith('@') ? username : '@$username';
  }

  String _initials(String name, String username) {
    final source = name == '-' ? username : name;
    if (source == '-') return '--';
    final clean = source.replaceAll('@', ' ').trim();
    final parts = clean
        .split(RegExp(r'\\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    final out = parts.take(2).map((e) => e[0]).join();
    return out.toUpperCase();
  }
}

class _PushRegisterDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _PushRegisterDialog({
    this.title = 'Enable push notifications?',
    this.message =
        'We will register this device so you can receive notifications. If you already allowed notifications, just continue.',
    this.confirmLabel = 'Enable',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PushUnregisterDialog extends StatelessWidget {
  const _PushUnregisterDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unregister push?',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "You're already registered. If you turn it off, this device will stop receiving notifications.",
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Unregister',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PushSettingsDialog extends StatelessWidget {
  const _PushSettingsDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Allow notifications',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Notifications are blocked for this device. Open settings to allow notifications and try again.",
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Later',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Open settings',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PushTestDialog extends StatelessWidget {
  const _PushTestDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Send test push?',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'We will send a sample notification to this device to confirm delivery.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Send',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePair {
  final String date;
  final String time;

  const _DatePair(this.date, this.time);
}

class _CompanyLink {
  final String label;
  final String url;

  const _CompanyLink({required this.label, required this.url});
}
