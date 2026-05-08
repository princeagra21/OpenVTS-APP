import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/models/admin_profile.dart';
import 'package:open_vts/core/models/superadmin_profile.dart';
import 'package:open_vts/app/router/app_route_paths.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_client_provider.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/network/api_paths.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/admin_profile_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/repositories/user_profile_repository.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/features/settings/settings_controller.dart';
import 'package:open_vts/features/settings/settings_navigation_grid.dart';
import 'package:open_vts/features/settings/settings_route_resolver.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';
import 'package:open_vts/features/settings/settings_state.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_header.dart';
import 'package:url_launcher/url_launcher.dart';

class RoleAwareSettingsContent extends StatefulWidget {
  const RoleAwareSettingsContent({super.key, required this.role});

  final SettingsRole role;

  @override
  State<RoleAwareSettingsContent> createState() =>
      _RoleAwareSettingsContentState();
}

class _RoleAwareSettingsContentState extends State<RoleAwareSettingsContent> {
  late final SettingsRoleConfig _config;
  late final SettingsController _controller;

  ApiClient? _api;
  AdminProfileRepository? _adminRepo;
  UserProfileRepository? _userRepo;
  SuperadminRepository? _superadminRepo;

  AdminProfile? _adminOrUserProfile;
  SettingsViewState _viewState = const SettingsViewState();

  @override
  void initState() {
    super.initState();
    _config = SettingsRouteResolver.configForRole(widget.role);
    _controller = SettingsController(
      config: _config,
      profileLoader: _loadProfileByRole,
    )..addListener(_handleControllerChange);

    _controller.loadProfile();
    if (widget.role == SettingsRole.superadmin) {
      _loadPushState();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final message = _controller.errorMessage;
    if (message == null) {
      _viewState = _viewState.copyWith(errorShown: false);
      return;
    }
    if (_viewState.errorShown || !mounted) return;

    _viewState = _viewState.copyWith(errorShown: true);
    _showError(message);
  }

  void _showInfo(String message) {
    if (!mounted) return;
    OpenVtsFeedback.info(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    OpenVtsFeedback.success(context, message);
  }

  void _showError(String message) {
    if (!mounted) return;
    OpenVtsFeedback.error(context, message);
  }

  void _ensureApi() {
    _api ??= ApiClientProvider.shared();
  }

  void _ensureAdminRepo() {
    _ensureApi();
    _adminRepo ??= AdminProfileRepository(api: _api!);
  }

  void _ensureUserRepo() {
    _ensureApi();
    _userRepo ??= UserProfileRepository(api: _api!);
  }

  void _ensureSuperadminRepo() {
    _ensureApi();
    _superadminRepo ??= SuperadminRepository(api: _api!);
  }

  Future<Result<SettingsProfileData>> _loadProfileByRole(
    CancelToken cancelToken,
  ) async {
    switch (widget.role) {
      case SettingsRole.admin:
        _ensureAdminRepo();
        final result = await _adminRepo!.getMyProfile(cancelToken: cancelToken);
        return result.when(
          success: (profile) {
            _adminOrUserProfile = profile;
            return Result.ok(
              _mapAdminLikeProfile(profile, useGranularVerification: true),
            );
          },
          failure: (error) => Result.fail(error),
        );

      case SettingsRole.user:
        _ensureUserRepo();
        final result = await _userRepo!.getMyProfile(cancelToken: cancelToken);
        return result.when(
          success: (profile) {
            _adminOrUserProfile = profile;
            return Result.ok(
              _mapAdminLikeProfile(profile, useGranularVerification: false),
            );
          },
          failure: (error) => Result.fail(error),
        );

      case SettingsRole.superadmin:
        _ensureSuperadminRepo();
        final result = await _superadminRepo!.getSuperadminProfile(
          cancelToken: cancelToken,
        );
        return result.when(
          success: (profile) {
            _adminOrUserProfile = null;
            return Result.ok(_mapSuperadminProfile(profile));
          },
          failure: (error) => Result.fail(error),
        );
    }
  }

  SettingsProfileData _mapAdminLikeProfile(
    AdminProfile profile, {
    required bool useGranularVerification,
  }) {
    final company = _companyMap(profile);
    final socialLinks = company['socialLinks'] is Map
        ? Map<String, dynamic>.from((company['socialLinks'] as Map).cast())
        : const <String, dynamic>{};

    final emailVerified = useGranularVerification
        ? profile.emailVerified
        : profile.isVerified;
    final phoneVerified = useGranularVerification
        ? profile.phoneVerified
        : profile.isVerified;

    return SettingsProfileData(
      profileId: profile.id,
      name: _display(profile.fullName),
      username: _usernameLabel(profile.username),
      verified: profile.isVerified,
      emailVerified: emailVerified,
      phoneVerified: phoneVerified,
      imageUrl: _extractProfileImageUrl(profile.raw),
      email: _display(profile.email),
      phone: _display(profile.phone),
      whatsapp: _extractWhatsapp(profile.raw),
      companyName: _display(company['name']?.toString() ?? profile.companyName),
      companyWebsite: _display(
        company['websiteUrl']?.toString() ?? profile.website,
      ),
      companyId: _display(company['id']?.toString()),
      primaryColor: _display(company['primaryColor']?.toString()),
      customDomain: _display(company['customDomain']?.toString()),
      socialLabels: _socialLabels(company),
      socialLinks: socialLinks,
      address: _display(_fullAddress(profile)),
      createdParts: _formatDateTimeParts(profile.createdAt),
      updatedParts: _formatDateTimeParts(
        profile.lastLoginAt.isNotEmpty
            ? profile.lastLoginAt
            : profile.lastLogin,
      ),
    );
  }

  SettingsProfileData _mapSuperadminProfile(SuperadminProfile profile) {
    final socialLinks = profile.company['socialLinks'] is Map
        ? Map<String, dynamic>.from(
            (profile.company['socialLinks'] as Map).cast(),
          )
        : const <String, dynamic>{};

    return SettingsProfileData(
      profileId: profile.id,
      name: _display(profile.fullName),
      username: _usernameLabel(profile.username),
      verified: profile.isVerified ?? false,
      emailVerified: profile.isVerified ?? false,
      phoneVerified: profile.isVerified ?? false,
      imageUrl: _extractProfileImageUrl(profile.raw),
      email: _display(profile.email),
      phone: _display(profile.phone),
      whatsapp: _extractWhatsapp(profile.raw),
      companyName: _display(profile.companyName),
      companyWebsite: _display(profile.website),
      companyId: _display(profile.company['id']?.toString()),
      primaryColor: _display(profile.company['primaryColor']?.toString()),
      customDomain: _display(profile.company['customDomain']?.toString()),
      socialLabels: profile.socialLabels,
      socialLinks: socialLinks,
      address: _display(_superadminAddress(profile)),
      createdParts: _formatDateTimeParts(profile.createdAt),
      updatedParts: _formatDateTimeParts(_superadminUpdatedAt(profile)),
    );
  }

  String _display(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _usernameLabel(String? value) {
    final text = _display(value);
    if (text == '-') return '-';
    return text.startsWith('@') ? text : '@$text';
  }

  String _buildAbsoluteUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';

    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }

    final baseUrl = AppConfig.fromDartDefine().baseUrl;
    if (baseUrl.isEmpty) return '';
    if (value.startsWith(AppRoutePaths.root)) return '$baseUrl$value';
    return '$baseUrl/$value';
  }

  String _extractProfileImageUrl(Map<String, dynamic> raw) {
    final sources = <Map<String, dynamic>>[raw];
    final level1 = raw['data'];
    if (level1 is Map) {
      final level1Map = Map<String, dynamic>.from(level1.cast());
      sources.add(level1Map);
      final level2 = level1Map['data'];
      if (level2 is Map) {
        sources.add(Map<String, dynamic>.from(level2.cast()));
      }
    }

    const keys = [
      'profileUrl',
      'profileurl',
      'profile_url',
      'avatarUrl',
      'avatar_url',
      'avatar',
      'photoUrl',
      'photo_url',
      'imageUrl',
      'image_url',
      'profileImage',
      'profile_image',
    ];

    for (final map in sources) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        return _buildAbsoluteUrl(text);
      }
    }

    return '';
  }

  String _extractWhatsapp(Map<String, dynamic> raw) {
    final sources = <Map<String, dynamic>>[raw];
    final level1 = raw['data'];
    if (level1 is Map) {
      final level1Map = Map<String, dynamic>.from(level1.cast());
      sources.add(level1Map);
      final level2 = level1Map['data'];
      if (level2 is Map) {
        sources.add(Map<String, dynamic>.from(level2.cast()));
      }
    }

    const keys = ['whatsapp', 'whatsappNumber', 'whatsapp_number'];
    for (final map in sources) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        return text;
      }
    }

    return '';
  }

  Map<String, dynamic> _companyMap(AdminProfile profile) {
    final companies = profile.data['companies'];
    if (companies is List && companies.isNotEmpty) {
      final first = companies.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first.cast());
      }
    }
    return const {};
  }

  String _fullAddress(AdminProfile profile) {
    final data = profile.data;
    final address = data['address'];
    if (address is Map) {
      final map = Map<String, dynamic>.from(address.cast());
      final full = (map['fullAddress'] ?? map['fulladdress'] ?? '')
          .toString()
          .trim();
      if (full.isNotEmpty) return full;
      final line = (map['addressLine'] ?? '').toString().trim();
      if (line.isNotEmpty) return line;
    }

    final parts = <String>[
      profile.addressLine.trim(),
      profile.city.trim(),
      profile.state.trim(),
      profile.country.trim(),
      profile.pincode.trim(),
    ].where((e) => e.isNotEmpty && e != '-').toList();

    return parts.join(', ');
  }

  String _superadminAddress(SuperadminProfile profile) {
    final address = profile.address;
    final full = (address['fullAddress'] ?? address['fulladdress'] ?? '')
        .toString()
        .trim();
    if (full.isNotEmpty) return full;
    final line = (address['addressLine'] ?? profile.addressLine)
        .toString()
        .trim();
    if (line.isNotEmpty) return line;
    return '';
  }

  String _superadminUpdatedAt(SuperadminProfile profile) {
    if (profile.lastLogin.isNotEmpty) return profile.lastLogin;
    final level1 = profile.raw['data'];
    if (level1 is Map) {
      final level2 = level1['data'];
      if (level2 is Map) {
        final updated = level2['updatedAt']?.toString().trim() ?? '';
        if (updated.isNotEmpty) return updated;
      }
    }
    return '';
  }

  List<String> _socialLabels(Map<String, dynamic> company) {
    final links = company['socialLinks'];
    if (links is Map) {
      return links.keys
          .map((k) => k.toString())
          .where((k) => k.trim().isNotEmpty)
          .map((k) {
            final lower = k.trim();
            if (lower.isEmpty) return '';
            return lower[0].toUpperCase() + lower.substring(1);
          })
          .where((k) => k.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<String> _formatDateTimeParts(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return const ['—', '—'];
    final dt = DateTime.tryParse(text)?.toLocal();
    if (dt == null) return const ['—', '—'];

    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${dt.month}/${dt.day}/${dt.year}';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:${two(dt.minute)} $ampm';
    return [date, time];
  }

  Future<void> _onEditProfile() async {
    final changed = await SettingsRouteResolver.openEditProfile(
      context: context,
      role: widget.role,
      profile: _controller.profile,
      adminOrUserProfile: _adminOrUserProfile,
    );
    if (changed) {
      await _controller.loadProfile();
    }
  }

  Future<void> _onUpdatePassword() async {
    final changed = await SettingsRouteResolver.openUpdatePassword(
      context: context,
      role: widget.role,
      profile: _controller.profile,
    );
    if (changed) {
      await _controller.loadProfile();
    }
  }

  Future<void> _sendAndVerifyAdminOtp(VerifyChannel channel) async {
    _ensureAdminRepo();
    await _sendAndVerifyOtp(
      title: channel == VerifyChannel.email
          ? 'Verify Email'
          : 'Verify WhatsApp',
      sendOtp: (token) {
        if (channel == VerifyChannel.email) {
          return _adminRepo!.sendEmailOtp(cancelToken: token);
        }
        return _adminRepo!.sendPhoneOtp(cancelToken: token);
      },
      verifyOtp: (code, token) {
        if (channel == VerifyChannel.email) {
          return _adminRepo!.verifyEmailOtp(code, cancelToken: token);
        }
        return _adminRepo!.verifyPhoneOtp(code, cancelToken: token);
      },
    );
  }

  Future<void> _sendAndVerifyUserOtp(VerifyChannel channel) async {
    _ensureUserRepo();
    await _sendAndVerifyOtp(
      title: channel == VerifyChannel.email
          ? 'Verify Email'
          : 'Verify WhatsApp',
      sendOtp: (token) {
        if (channel == VerifyChannel.email) {
          return _userRepo!.sendEmailOtp(cancelToken: token);
        }
        return _userRepo!.sendPhoneOtp(cancelToken: token);
      },
      verifyOtp: (code, token) {
        if (channel == VerifyChannel.email) {
          return _userRepo!.verifyEmailOtp(code, cancelToken: token);
        }
        return _userRepo!.verifyPhoneOtp(code, cancelToken: token);
      },
    );
  }

  Future<void> _sendAndVerifyOtp({
    required String title,
    required Future<Result<void>> Function(CancelToken token) sendOtp,
    required Future<Result<void>> Function(String code, CancelToken token)
    verifyOtp,
  }) async {
    if (!mounted) return;

    final sendToken = CancelToken();
    final sendRes = await sendOtp(sendToken);

    if (!mounted) return;
    final bool? verified = await sendRes.when(
      success: (_) async {
        return OpenVtsModal.showBottomSheet<bool>(
          context: context,
          child: _OtpVerifySheet(title: title, onVerify: verifyOtp),
        );
      },
      failure: (error) async {
        var msg = 'Could not send OTP.';
        if (error is ApiException) {
          if (error.statusCode == 401 || error.statusCode == 403) {
            msg = 'Not authorized to request verification.';
          } else if (error.message.trim().isNotEmpty) {
            msg = error.message;
          }
        }
        _showError(msg);
        return false;
      },
    );

    if (verified == true) {
      await _controller.loadProfile();
    }
  }

  Future<void> _loadPushState() async {
    final state = await PushNotificationsService.instance.getStatus();
    if (!mounted) return;
    setState(() => _viewState = _viewState.copyWith(pushState: state));
  }

  Future<void> _openNotificationSettings() async {
    final uri = Uri.parse('app-settings:');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    if (!mounted) return;
    _showInfo(
      'Open your device settings and allow notifications for this app.',
    );
  }

  Future<void> _handlePushRegister() async {
    if (_viewState.pushActionLoading) return;

    setState(() => _viewState = _viewState.copyWith(pushActionLoading: true));
    final res = await PushNotificationsService.instance.enable();
    if (!mounted) return;

    res.when(
      success: (state) {
        setState(
          () => _viewState = _viewState.copyWith(
            pushState: state,
            pushActionLoading: false,
          ),
        );
        _showSuccess('Push enabled.');
      },
      failure: (err) async {
        setState(
          () => _viewState = _viewState.copyWith(pushActionLoading: false),
        );
        final msg = err is ApiException
            ? (err.message.isNotEmpty
                  ? err.message
                  : 'Push could not be enabled.')
            : 'Push could not be enabled.';
        _showError(msg);
        if (err is ApiException &&
            err.message.toLowerCase().contains('permission')) {
          await _showPushPermissionDialog();
        }
      },
    );
  }

  Future<void> _handlePushUnregister() async {
    if (_viewState.pushActionLoading) return;

    setState(() => _viewState = _viewState.copyWith(pushActionLoading: true));
    final res = await PushNotificationsService.instance.disable();
    if (!mounted) return;

    res.when(
      success: (_) async {
        await _loadPushState();
        if (!mounted) return;
        setState(
          () => _viewState = _viewState.copyWith(pushActionLoading: false),
        );
        _showInfo('Push disabled.');
      },
      failure: (err) {
        setState(
          () => _viewState = _viewState.copyWith(pushActionLoading: false),
        );
        final msg = err is ApiException
            ? (err.message.isNotEmpty
                  ? err.message
                  : 'Push could not be disabled.')
            : 'Push could not be disabled.';
        _showError(msg);
      },
    );
  }

  Future<void> _showPushPermissionDialog() async {
    final shouldOpen = await OpenVtsModal.showConfirmDialog(
      context: context,
      title: 'Enable push notifications?',
      message:
          'Enable push notifications to get important updates and alerts on this device.',
      confirmLabel: 'Open Settings',
    );
    if (shouldOpen) {
      await _openNotificationSettings();
    }
  }

  Future<void> _confirmPushAction() async {
    final state =
        _viewState.pushState ??
        await PushNotificationsService.instance.getStatus();
    if (!mounted) return;

    if (state.registered) {
      final confirmed = await OpenVtsModal.showConfirmDialog(
        context: context,
        title: 'Unregister push?',
        message: 'This device will stop receiving push notifications.',
        confirmLabel: 'Unregister',
      );
      if (confirmed) {
        await _handlePushUnregister();
      }
      return;
    }

    final confirmed = await OpenVtsModal.showConfirmDialog(
      context: context,
      title: 'Enable push notifications?',
      message:
          'Enable push notifications to get important updates and alerts on this device.',
      confirmLabel: 'Enable',
    );
    if (confirmed) {
      await _handlePushRegister();
    }
  }

  Future<void> _handlePushTest() async {
    final state =
        _viewState.pushState ??
        await PushNotificationsService.instance.getStatus();
    if (!mounted) return;

    if (!state.registered) {
      final confirmed = await OpenVtsModal.showConfirmDialog(
        context: context,
        title: 'Enable push to test?',
        message:
            'Push is not enabled yet. Turn it on so we can send a test notification to this device.',
        confirmLabel: 'Enable',
      );
      if (confirmed) {
        await _handlePushRegister();
      }
      return;
    }

    final confirmed = await OpenVtsModal.showConfirmDialog(
      context: context,
      title: 'Send test push?',
      message: 'We will send a test notification to this device.',
      confirmLabel: 'Send',
    );
    if (!confirmed) return;
    if (!mounted) return;

    _showInfo('Test push queued.');
  }

  String _responseMessage(
    Object? data, {
    String fallback = 'Request completed.',
  }) {
    if (data is Map) {
      final root = data.cast<dynamic, dynamic>();
      final direct = root['message']?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;
      final nestedData = root['data'];
      if (nestedData is Map) {
        final nested = nestedData['message']?.toString().trim();
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return fallback;
  }

  Future<void> _requestEmailOtp() async {
    if (_viewState.emailOtpLoading) return;

    _ensureApi();
    setState(() => _viewState = _viewState.copyWith(emailOtpLoading: true));
    final res = await _api!.post(SuperadminApiPaths.profileVerifyEmailRequest);
    if (!mounted) return;

    setState(() => _viewState = _viewState.copyWith(emailOtpLoading: false));
    res.when(
      success: (data) {
        _showInfo(_responseMessage(data, fallback: 'Email OTP request sent.'));
      },
      failure: (err) {
        final msg = err is ApiException && err.message.trim().isNotEmpty
            ? err.message
            : 'Failed to request email OTP.';
        _showError(msg);
      },
    );
  }

  Future<void> _requestWhatsappOtp() async {
    if (_viewState.whatsappOtpLoading) return;

    _ensureApi();
    setState(() => _viewState = _viewState.copyWith(whatsappOtpLoading: true));
    final res = await _api!.post(
      SuperadminApiPaths.profileVerifyWhatsappRequest,
    );
    if (!mounted) return;

    setState(() => _viewState = _viewState.copyWith(whatsappOtpLoading: false));
    res.when(
      success: (data) {
        _showInfo(
          _responseMessage(data, fallback: 'WhatsApp OTP request sent.'),
        );
      },
      failure: (err) {
        final msg = err is ApiException && err.message.trim().isNotEmpty
            ? err.message
            : 'Failed to request WhatsApp OTP.';
        _showError(msg);
      },
    );
  }

  Widget _buildRoleAppBar() {
    return SettingsRouteResolver.buildRoleAppBar(
      context: context,
      role: widget.role,
    );
  }

  Widget _buildLocalizationSection() {
    return SettingsRouteResolver.buildLocalizationSection(widget.role);
  }

  Widget _buildSettingsSection() {
    return SettingsRouteResolver.buildSettingsSection(widget.role);
  }

  Widget _buildProfileSection(SettingsProfileData profile, bool loading) {
    final onEmailVerify = switch (widget.role) {
      SettingsRole.admin => () => _sendAndVerifyAdminOtp(VerifyChannel.email),
      SettingsRole.user => () => _sendAndVerifyUserOtp(VerifyChannel.email),
      SettingsRole.superadmin => _requestEmailOtp,
    };

    final onPhoneVerify = switch (widget.role) {
      SettingsRole.admin => () => _sendAndVerifyAdminOtp(
        VerifyChannel.whatsapp,
      ),
      SettingsRole.user => () => _sendAndVerifyUserOtp(VerifyChannel.whatsapp),
      SettingsRole.superadmin => _requestWhatsappOtp,
    };

    final showSuperadminRequestActions = widget.role == SettingsRole.superadmin;

    return Column(
      children: [
        SettingsProfileHeader(
          profile: profile,
          loading: loading,
          onEdit: _onEditProfile,
          onPassword: _onUpdatePassword,
          onEmailVerify: onEmailVerify,
          onPhoneVerify: onPhoneVerify,
          emailActionVisibleWhenVerified: showSuperadminRequestActions,
          phoneActionVisibleWhenVerified: showSuperadminRequestActions,
          emailActionLoading: _viewState.emailOtpLoading,
          phoneActionLoading: _viewState.whatsappOtpLoading,
          errorMessage: _controller.errorMessage,
          onRetry: () => _controller.loadProfile(),
        ),
        if (widget.role == SettingsRole.superadmin) ...[
          const SizedBox(height: 16),
          _PushDiagnosticsCard(
            state: _viewState.pushState,
            loading: _viewState.pushActionLoading,
            onConfirmAction: _confirmPushAction,
            onSendTest: _handlePushTest,
          ),
        ],
      ],
    );
  }

  Widget _buildSection(
    SettingsSectionId section,
    bool loading,
    SettingsProfileData profile,
  ) {
    switch (section) {
      case SettingsSectionId.profile:
        return _buildProfileSection(profile, loading);
      case SettingsSectionId.localization:
        return _buildLocalizationSection();
      case SettingsSectionId.settings:
        return _buildSettingsSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final selectedSection = _controller.selectedSection;
        final profile = _controller.profile;
        final loading = _controller.loadingProfile;

        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? OpenVtsColors.panelDark
              : OpenVtsColors.panelLight,
          body: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    topPadding + AppUtils.appBarHeightCustom + 10,
                    padding,
                    padding,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsNavigationGrid(
                          config: _config,
                          selectedSection: selectedSection,
                          onSectionSelected: _controller.selectSection,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(selectedSection, loading, profile),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: padding,
                right: padding,
                top: 0,
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? OpenVtsColors.panelDark
                      : OpenVtsColors.panelLight,
                  child: _buildRoleAppBar(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OtpVerifySheet extends StatefulWidget {
  const _OtpVerifySheet({required this.title, required this.onVerify});

  final String title;
  final Future<Result<void>> Function(String code, CancelToken token) onVerify;

  @override
  State<_OtpVerifySheet> createState() => _OtpVerifySheetState();
}

class _OtpVerifySheetState extends State<_OtpVerifySheet> {
  final TextEditingController _otpController = TextEditingController();
  CancelToken? _token;
  bool _verifying = false;
  bool _verifyErrorShown = false;

  @override
  void dispose() {
    _token?.cancel('OTP verify dialog disposed');
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;

    final code = _otpController.text.trim();
    if (code.isEmpty) {
      if (!mounted) return;
      OpenVtsFeedback.warning(context, 'Please enter OTP.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _verifying = true;
      _verifyErrorShown = false;
    });

    _token?.cancel('New OTP verify started');
    final token = CancelToken();
    _token = token;

    try {
      final result = await widget.onVerify(code, token);
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _verifying = false);
          OpenVtsFeedback.success(context, 'Verified successfully');
          Navigator.of(context).pop(true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _verifying = false);
          if (_verifyErrorShown) return;
          _verifyErrorShown = true;

          var msg = 'Could not verify OTP.';
          if (error is ApiException) {
            if (error.statusCode == 401 || error.statusCode == 403) {
              msg = 'Not authorized to verify.';
            } else if (error.message.trim().isNotEmpty) {
              msg = error.message;
            }
          }
          OpenVtsFeedback.error(context, msg);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _verifying = false);
      if (_verifyErrorShown) return;
      _verifyErrorShown = true;
      OpenVtsFeedback.error(context, 'Could not verify OTP.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final titleSize = AdaptiveUtils.getSubtitleFontSize(width);
    final labelSize = AdaptiveUtils.getTitleFontSize(width);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppFonts.inter(
                      fontSize: titleSize + 1,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _verifying
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close,
                      size: 18 * scale,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                counterText: '',
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _verifying
                    ? const AppShimmer(width: 42, height: 12, radius: 6)
                    : Text(
                        'Verify OTP',
                        style: AppFonts.inter(
                          fontSize: labelSize,
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PushDiagnosticsCard extends StatelessWidget {
  const _PushDiagnosticsCard({
    required this.state,
    required this.loading,
    required this.onConfirmAction,
    required this.onSendTest,
  });

  final PushDeviceState? state;
  final bool loading;
  final VoidCallback onConfirmAction;
  final VoidCallback onSendTest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final headingFs = 18 * scale;
    final subtitleFs = 12 * scale;
    final alertFs = 12 * scale;

    if (loading || state == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppShimmer(width: 132, height: 18, radius: 6),
            const SizedBox(height: 4),
            const AppShimmer(width: 176, height: 12, radius: 6),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 10.0;
                final cellWidth = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: cellWidth,
                      child: const AppShimmer(
                        width: double.infinity,
                        height: 64,
                        radius: 12,
                      ),
                    ),
                    SizedBox(
                      width: cellWidth,
                      child: const AppShimmer(
                        width: double.infinity,
                        height: 64,
                        radius: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const AppShimmer(width: double.infinity, height: 48, radius: 12),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(
                  child: AppShimmer(
                    width: double.infinity,
                    height: 44,
                    radius: 12,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: AppShimmer(
                    width: double.infinity,
                    height: 44,
                    radius: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final permissionLabel = !state!.supported
        ? 'Unsupported'
        : (state!.registered
              ? 'Allowed'
              : (state!.askedOnce ? 'Blocked' : 'Not requested'));
    final tokenLabel = state!.token?.isNotEmpty == true ? 'Registered' : 'None';
    final showPermissionWarning = state!.supported && !state!.enabledByUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Push Diagnostics',
            style: AppFonts.roboto(
              fontSize: headingFs,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Notification permission and push state',
            style: AppFonts.roboto(
              fontSize: subtitleFs,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final cellWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: 'Permission',
                      value: permissionLabel,
                      width: width,
                      colorScheme: cs,
                    ),
                  ),
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: 'Server Tokens',
                      value: tokenLabel,
                      width: width,
                      colorScheme: cs,
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.roboto(
                        fontSize: alertFs,
                        height: 17 / 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
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
                  onPressed: loading ? null : onConfirmAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    state!.registered ? Icons.notifications_off : Icons.refresh,
                    size: 16 * scale,
                    color: cs.onPrimary,
                  ),
                  label: Text(
                    state!.registered ? 'Unregister' : 'Re-register',
                    style: AppFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onSendTest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.send, size: 16 * scale, color: cs.onSurface),
                  label: Text(
                    'Send push test',
                    style: AppFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
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
    required double width,
    required ColorScheme colorScheme,
  }) {
    final labelFs = AdaptiveUtils.getTitleFontSize(width) + 1;
    final valueFs = AdaptiveUtils.getSubtitleFontSize(width) - 2;

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
            style: AppFonts.roboto(
              fontSize: labelFs,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.roboto(
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
}
