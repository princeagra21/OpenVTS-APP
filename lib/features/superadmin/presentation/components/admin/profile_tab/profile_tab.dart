import 'package:open_vts/core/theme/app_fonts.dart';
// components/admin/profile_tab.dart
import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/edit_company_screen.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/update_password_screen.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/edit_admin_profile_screen.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/widget/delete_account_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/superadmin/di/superadmin_core_gateway_providers.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

part 'profile_tab_sections.dart';
part 'profile_tab_helpers.dart';
part 'profile_tab_push_dialogs.dart';

class ProfileTab extends ConsumerStatefulWidget {
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
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  AdminProfile? _profile;
  bool _loading = false;
  bool _statusSubmitting = false;
  bool? _activeOverride;
  bool _errorShown = false;
  bool _loadFailed = false;
  bool _pushActionLoading = false;
  PushDeviceState? _pushState;

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
    super.dispose();
  }

  Future<void> _loadPushState() async {
    final state = await PushNotificationsService.instance.getStatus();
    if (!mounted) return;
    updateLocalUiState(this, () {
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
    updateLocalUiState(this, () => _pushActionLoading = true);
    final res = await PushNotificationsService.instance.enable();
    if (!mounted) return;
    res.when(
      success: (state) {
        updateLocalUiState(this, () {
          _pushState = state;
          _pushActionLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Push enabled.')));
      },
      failure: (err) async {
        updateLocalUiState(this, () => _pushActionLoading = false);
        final msg = 'Push could not be enabled.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));        await _showPushPermissionDialog();
      },
    );
  }

  Future<void> _handlePushUnregister() async {
    if (_pushActionLoading) return;
    updateLocalUiState(this, () => _pushActionLoading = true);
    final res = await PushNotificationsService.instance.disable();
    if (!mounted) return;
    res.when(
      success: (_) async {
        await _loadPushState();
        if (!mounted) return;
        updateLocalUiState(this, () => _pushActionLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Push disabled.')));
      },
      failure: (err) {
        updateLocalUiState(this, () => _pushActionLoading = false);
        final msg = 'Push could not be disabled.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
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
      MaterialPageRoute(builder: (_) => EditCompanyScreen(profile: profile)),
    );
    if (!mounted) return;
    if (updated == true) {
      await _loadProfile();
    }
  }


  Future<void> _loadProfile() async {

    if (!mounted) return;
    updateLocalUiState(this, () => _loading = true);

    try {
      final res = await ref.read(getSuperadminAdminGatewayUseCaseProvider).getAdminProfile(widget.adminId);
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (!mounted || profile is! AdminProfile) return;
          final active = _readActive(profile);
          updateLocalUiState(this, () {
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
          updateLocalUiState(this, () {
            _loading = false;
            _loadFailed = true;
          });
          if (_errorShown) return;
          _errorShown = true;

          final msg = "Couldn't load admin profile.";
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
      updateLocalUiState(this, () {
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
    updateLocalUiState(this, () => _statusSubmitting = true);
    final currentActive = _activeOverride ?? profile.isActive;
    try {
      final res = await ref.read(getSuperadminAdminGatewayUseCaseProvider).updateAdminStatus(widget.adminId, !currentActive);
      if (!mounted) return;
      res.when(
        success: (_) async {
          updateLocalUiState(this, () => _activeOverride = !currentActive);
          widget.onStatusChanged?.call();
          await _loadProfile();
          if (!mounted) return;
          updateLocalUiState(this, () => _statusSubmitting = false);
        },
        failure: (_) {
          if (!mounted) return;
          updateLocalUiState(this, () => _statusSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't update status.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      updateLocalUiState(this, () => _statusSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't update status.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShimmer(width: double.infinity, height: 360, radius: 12);
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
}
